# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/conversions'
require 'json'

# TODO: Move the validation & inserting of defaults to its own section
# Right now everything is intermingled so everything is checking for nils and missing keys
# maybe another class so we can do stuff like `@request_schema.path` & `@request_schema.headers`?

module Rswag
  module Specs
    class RequestFactory # rubocop:disable Metrics/ClassLength
      STYLE_SEPARATORS = {
        form: ',',
        spaceDelimited: '%20',
        pipeDelimited: '|'
      }.freeze
      RACK_FORMATTED_HEADER_KEYS = {
        'Accept' => 'HTTP_ACCEPT',
        'Content-Type' => 'CONTENT_TYPE',
        'Authorization' => 'HTTP_AUTHORIZATION',
        'Host' => 'HTTP_HOST'
      }.freeze
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
          add_path(request, metadata, openapi_spec, parameters)
          add_headers(request, metadata, openapi_spec, parameters, example)
          add_payload(request, parameters, example)
        end
      end

      private

      def expand_parameters(metadata, openapi_spec, _example)
        operation_params = metadata[:operation][:parameters] || []
        path_item_params = metadata[:path_item][:parameters] || []
        security_params = derive_security_params(metadata, openapi_spec)

        # NOTE: Use of + instead of concat to avoid mutation of the metadata object
        (operation_params + path_item_params + security_params)
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref'], openapi_spec) : p }
          .uniq { |p| p[:name] }
          .reject { |p| p[:required] == false && !headers.key?(p[:name]) && !params.key?(p[:name]) }
      end

      def derive_security_params(metadata, openapi_spec)
        requirements = metadata[:operation][:security] || openapi_spec[:security] || []
        scheme_names = requirements.flat_map(&:keys)
        schemes = security_version(scheme_names, openapi_spec)

        schemes.map do |scheme|
          param = scheme[:type] == :apiKey ? scheme.slice(:name, :in) : { name: 'Authorization', in: :header }
          param.merge(schema: { type: :string }, required: requirements.one?)
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

      def key_version(ref, _openapi_spec)
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
        return '' if openapi_spec[:servers].blank?

        server = openapi_spec[:servers].first
        variables = {}
        server.fetch(:variables, {}).each_pair { |k, v| variables[k] = v[use_server] }
        base_path = server[:url].gsub(/\{(.*?)\}/) { variables[::Regexp.last_match(1).to_sym] }
        URI(base_path).path
      end

      def add_path(request, metadata, openapi_spec, parameters)
        template = base_path_from_servers(openapi_spec) + metadata[:path_item][:template]

        parameters.select { |p| p[:in] == :path }.each do |p|
          template.gsub!("{#{p[:name]}}", params.fetch(p[:name].to_s).to_s)
        rescue KeyError
          raise ArgumentError, ("`#{p[:name]}`" \
            'parameter key present, but not defined within example group (i. e `it` or `let` block)')
        end

        query_strings = parameters.select { |p| p[:in] == :query && params.key?(p[:name]) }
                                  .filter_map { |p| build_query_string_part(p, params[p[:name]]) }
        request[:path] = query_strings.any? ? "#{template}?#{query_strings.join('&')}" : template
      end

      def build_query_string_part(param, value) # rubocop:todo Metrics/MethodLength
        raise ArgumentError, "'type' is not supported field for Parameter" unless param[:type].nil?
        # NOTE: https://swagger.io/docs/specification/serialization/
        return unless param[:schema]

        escaped_name = CGI.escape(param[:name].to_s)
        style = param[:style]&.to_sym || :form
        explode = param[:explode].nil? ? true : param[:explode]
        type = param.dig(:schema, :type)&.to_sym

        case [type, style, explode]
        in [:object, :deepObject, _] then { param[:name] => value }.to_query
        in [:object, :form, true] then value.to_query
        in [:object, :form, _] then "#{escaped_name}=#{escaped_array(value).join(',')}"
        in [:array, _, true] then escaped_array(value).map { |v| "#{escaped_name}=#{v}" }.join('&')
        in [:array, _, _] then "#{escaped_name}=#{escaped_array(value).join(STYLE_SEPARATORS[style])}"
        else "#{escaped_name}=#{CGI.escape(value.to_s)}"
        end
      end

      def escaped_array(value) = value.to_a.flatten.map { |v| CGI.escape(v.to_s) }

      def add_headers(request, metadata, openapi_spec, parameters, example)
        tuples = parameters.filter_map { |p| [p[:name], headers.fetch(p[:name]).to_s] if p[:in] == :header }

        # Accept header
        produces = metadata[:operation][:produces] || openapi_spec[:produces]
        tuples << ['Accept', headers.fetch('Accept', produces.first)] if produces

        # Content-Type header
        consumes = metadata[:operation][:consumes] || openapi_spec[:consumes]
        tuples << ['Content-Type', headers.fetch('Content-Type', consumes.first)] if consumes

        # Host header
        host = metadata[:operation][:host] || openapi_spec[:host]
        tuples << ['Host', example.try(:Host) || host] if host.present?

        # Rails test infrastructure requires rack-formatted headers
        request[:headers] = tuples.each_with_object({}) do |pair, headers|
          headers[RACK_FORMATTED_HEADER_KEYS.fetch(pair[0], pair[0])] = pair[1]
        end
      end

      def add_payload(request, parameters, example)
        content_type = request[:headers]['CONTENT_TYPE']
        return if content_type.nil?

        request[:payload] = if ['application/x-www-form-urlencoded', 'multipart/form-data'].include?(content_type)
                              build_form_payload(parameters, example)
                            elsif %r{\Aapplication/([0-9A-Za-z._-]+\+json\z|json\z)}.match?(content_type)
                              build_json_payload(parameters, example)
                            else
                              build_raw_payload(parameters, example)
                            end
      end

      def build_form_payload(parameters, _example)
        # See http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
        # Rather that serializing with the appropriate encoding (e.g. multipart/form-data),
        # Rails test infrastructure allows us to send the values directly as a hash
        # PROS: simple to implement, CONS: serialization/deserialization is bypassed in test
        tuples = parameters
                 .select { |p| p[:in] == :formData }
                 .map { |p| [p[:name], params.fetch(p[:name])] }
        Hash[tuples]
      end

      def build_raw_payload(parameters, _example)
        body_param = parameters.find { |p| p[:in] == :body }
        return nil unless body_param

        begin
          json_payload = params.fetch(body_param[:name].to_s)
        rescue KeyError
          raise(MissingParameterError, body_param[:name])
        end

        json_payload
      end

      def build_json_payload(parameters, example)
        build_raw_payload(parameters, example)&.to_json
      end

      def doc_version(doc)
        doc[:openapi]
      end
    end

    class MissingParameterError < StandardError
      attr_reader :body_param

      def initialize(body_param)
        super()
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
