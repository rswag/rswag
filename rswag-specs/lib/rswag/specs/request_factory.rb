# frozen_string_literal: true
require "active_support"
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/conversions'
require 'json'

module Rswag
  module Specs
    class RequestFactory
      attr_accessor :example, :metadata, :params, :headers
      def initialize(metadata, example, config = ::Rswag::Specs.config)
        @config = config
        @example = example
        @metadata = metadata
        @params = example.respond_to?(:request_params) ? example.request_params : {}
        @headers = example.respond_to?(:request_headers) ? example.request_headers : {}
      end

      def build_request
        openapi_spec = @config.get_openapi_spec(metadata[:openapi_spec])
        parameters = expand_parameters(metadata, openapi_spec, example)

        {}.tap do |request|
          add_verb(request, metadata)
          add_path(request, metadata, openapi_spec, parameters, example)
          add_headers(request, metadata, openapi_spec, parameters, example)
          add_payload(request, parameters, example)
        end
      end

      private

      def expand_parameters(metadata, openapi_spec, example)
        operation_params = metadata[:operation][:parameters] || []
        path_item_params = metadata[:path_item][:parameters] || []
        security_params = derive_security_params(metadata, openapi_spec)

        # NOTE: Use of + instead of concat to avoid mutation of the metadata object
        (operation_params + path_item_params + security_params)
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref'], openapi_spec) : p }
          .uniq { |p| p[:name] }
          .reject { |p| p[:required] == false && !headers.key?(extract_getter(p)) && !params.key?(extract_getter(p)) }
      end

      def derive_security_params(metadata, openapi_spec)
        requirements = metadata[:operation][:security] || openapi_spec[:security] || []
        scheme_names = requirements.flat_map(&:keys)
        schemes = security_version(scheme_names, openapi_spec)

        schemes.map do |scheme|
          param = (scheme[:type] == :apiKey) ? scheme.slice(:name, :in) : { name: 'Authorization', in: :header }
          param.merge(type: :string, required: requirements.one?)
        end
      end

      def security_version(scheme_names, openapi_spec)
        components = openapi_spec[:components] || {}
        (components[:securitySchemes] || {}).slice(*scheme_names).values
      end

      def resolve_parameter(ref, openapi_spec)
        key = key_version(ref, openapi_spec)
        definitions = definition_version(openapi_spec)
        raise "Referenced parameter '#{ref}' must be defined" unless definitions && definitions[key]

        definitions[key]
      end

      def key_version(ref, openapi_spec)
        ref.sub('#/components/parameters/', '').to_sym
      end

      def definition_version(openapi_spec)
        components = openapi_spec[:components] || {}
        components[:parameters]
      end

      def add_verb(request, metadata)
        request[:verb] = metadata[:operation][:verb]
      end

      def base_path_from_servers(openapi_spec, use_server = :default)
        return '' if openapi_spec[:servers].nil? || openapi_spec[:servers].empty?
        server = openapi_spec[:servers].first
        variables = {}
        server.fetch(:variables, {}).each_pair { |k,v| variables[k] = v[use_server] }
        base_path = server[:url].gsub(/\{(.*?)\}/) { variables[$1.to_sym] }
        URI(base_path).path
      end

      def add_path(request, metadata, openapi_spec, parameters, example)
        template = base_path_from_servers(openapi_spec) + metadata[:path_item][:template]

        request[:path] = template.tap do |path_template|
          parameters.select { |p| p[:in] == :path }.each do |p|
            unless params.fetch(extract_getter(p).to_s)
              raise ArgumentError.new("`#{extract_getter(p).to_s}` parameter key present, but not defined within example group"\
                "(i. e `it` or `let` block)")
            end
            path_template.gsub!("{#{p[:name]}}", params.fetch(extract_getter(p)).to_s)
          end

          parameters.select { |p| p[:in] == :query && params.key?(p[:name]) }.each_with_index do |p, i|
            path_template.concat(i.zero? ? '?' : '&')
            path_template.concat(build_query_string_part(p, params.fetch(extract_getter(p)), openapi_spec))
          end
        end
      end

      def build_query_string_part(param, value, openapi_spec)
        name = param[:name]
        escaped_name = CGI.escape(name.to_s)

        # NOTE: https://swagger.io/docs/specification/serialization/
        if param[:schema]
          style = param[:style]&.to_sym || :form
          explode = param[:explode].nil? ? true : param[:explode]

          case param[:schema][:type]&.to_sym
          when :object
            case style
            when :deepObject
              return { name => value }.to_query
            when :form
              if explode
                return value.to_query
              else
                return "#{escaped_name}=" + value.to_a.flatten.map{|v| CGI.escape(v.to_s) }.join(',')
              end
            end
          when :array
            case explode
            when true
              return value.to_a.flatten.map{|v| "#{escaped_name}=#{CGI.escape(v.to_s)}"}.join('&')
            else
              separator = case style
                          when :form then ','
                          when :spaceDelimited then '%20'
                          when :pipeDelimited then '|'
                          end
              return "#{escaped_name}=" + value.to_a.flatten.map{|v| CGI.escape(v.to_s) }.join(separator)
            end
          else
            return "#{name}=#{value}"
          end
        end

        type = param[:type] || param.dig(:schema, :type)
        return "#{escaped_name}=#{CGI.escape(value.to_s)}" unless type&.to_sym == :array

        case param[:collectionFormat]
        when :ssv
          "#{name}=#{value.join(' ')}"
        when :tsv
          "#{name}=#{value.join('\t')}"
        when :pipes
          "#{name}=#{value.join('|')}"
        when :multi
          value.map { |v| "#{name}=#{v}" }.join('&')
        else
          "#{name}=#{value.join(',')}" # csv is default
        end
      end

      def add_headers(request, metadata, openapi_spec, parameters, example)
        tuples = parameters
          .select { |p| p[:in] == :header }
          .map { |p| [p[:name], headers.fetch(extract_getter(p)).to_s] }

        # Accept header
        produces = metadata[:operation][:produces] || openapi_spec[:produces]
        if produces
          accept = headers.fetch("Accept", produces.first)
          tuples << ['Accept', accept]
        end

        # Content-Type header
        consumes = metadata[:operation][:consumes] || openapi_spec[:consumes]
        if consumes
          content_type = headers.fetch('Content-Type', consumes.first)
          tuples << ['Content-Type', content_type]
        end

        # Host header
        host = metadata[:operation][:host] || openapi_spec[:host]
        if host.present?
          host = example.respond_to?(:'Host') ? example.send(:'Host') : host
          tuples << ['Host', host]
        end

        # Rails test infrastructure requires rack-formatted headers
        rack_formatted_tuples = tuples.map do |pair|
          [
            case pair[0]
              when 'Accept' then 'HTTP_ACCEPT'
              when 'Content-Type' then 'CONTENT_TYPE'
              when 'Authorization' then 'HTTP_AUTHORIZATION'
              when 'Host' then 'HTTP_HOST'
              else pair[0]
            end,
            pair[1]
          ]
        end

        request[:headers] = Hash[rack_formatted_tuples]
      end

      def add_payload(request, parameters, example)
        content_type = request[:headers]['CONTENT_TYPE']
        return if content_type.nil?

        if ['application/x-www-form-urlencoded', 'multipart/form-data'].include?(content_type)
          request[:payload] = build_form_payload(parameters)
        else
          request[:payload] = build_json_payload(parameters)
        end
      end

      def build_form_payload(parameters)
        # See http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
        # Rather that serializing with the appropriate encoding (e.g. multipart/form-data),
        # Rails test infrastructure allows us to send the values directly as a hash
        # PROS: simple to implement, CONS: serialization/deserialization is bypassed in test
        tuples = parameters
          .select { |p| p[:in] == :formData }
          .map { |p| [p[:name], params.fetch(extract_getter(p))] }
        Hash[tuples]
      end

      def build_json_payload(parameters)
        body_param = parameters.select { |p| p[:in] == :body }.first

        return nil unless body_param

        raise(MissingParameterError, body_param[:name]) unless example.respond_to?(body_param[:name])

        params.fetch(body_param[:name]).to_json
      end

      def doc_version(doc)
        doc[:openapi]
      end

      def extract_getter(parameter)
         parameter[:getter] || parameter[:name]
      end
    end

    class MissingParameterError < StandardError
      attr_reader :body_param

      def initialize(body_param)
        @body_param = body_param
      end

      def message
        <<~MSG
          Missing parameter '#{body_param}'

          Please check your spec. It looks like you defined a body parameter,
          but did not declare usage via let. Try adding:

              let(:#{body_param}) {}
        MSG
      end

    end
  end
end
