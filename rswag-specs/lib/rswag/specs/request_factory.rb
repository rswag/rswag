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
      CLEAN_PARAM = Struct.new(:escaped_array, :escaped_value, :escaped_name, :explode, :schema, :style, :type)
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
      EMPTY_PARAMETER_GROUPS = { body: [], path: [], query: [], formData: [], header: [] }.freeze
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

        parameter_groups = parameters.group_by { |p| p[:in] }.reverse_merge(EMPTY_PARAMETER_GROUPS)
        {}.tap do |request|
          request[:verb] = metadata[:operation][:verb]
          request[:path] = build_path_string(metadata, openapi_spec, parameter_groups[:path]) +
                           build_query_string(parameter_groups[:query])
          request[:headers] = build_headers(metadata, openapi_spec, parameter_groups[:header], example)
          request[:payload] = build_payload(request, parameters, example)
        end
      end

      private

      def expand_parameters(metadata, openapi_spec, _example)
        expandable_parameters = [
          *metadata[:operation][:parameters],
          *metadata[:path_item][:parameters],
          *derive_security_params(metadata, openapi_spec)
        ]

        expandable_parameters
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref'], openapi_spec) : p }
          .uniq { |p| p[:name] }
          .reject { |p| p[:required] == false && !headers.key?(p[:name]) && !params.key?(p[:name]) }
      end

      def derive_security_params(metadata, openapi_spec)
        requirements = metadata[:operation][:security] || openapi_spec[:security] || []
        scheme_names = requirements.flat_map(&:keys)
        schemes = (openapi_spec.dig(:components, :securitySchemes) || {}).slice(*scheme_names).values

        schemes.map do |scheme|
          param = scheme[:type] == :apiKey ? scheme.slice(:name, :in) : { name: 'Authorization', in: :header }
          param.merge(schema: { type: :string }, required: requirements.one?)
        end
      end

      def resolve_parameter(ref, openapi_spec)
        key_version = ref.sub('#/components/parameters/', '').to_sym
        definitions = (openapi_spec[:components] || {})[:parameters]
        raise "Referenced parameter '#{ref}' must be defined" unless definitions&.dig(key_version)

        definitions[key_version]
      end

      def base_path_from_servers(openapi_spec, use_server = :default)
        return '' if openapi_spec[:servers].blank?

        server = openapi_spec[:servers].first
        variables = {}
        server.fetch(:variables, {}).each_pair { |k, v| variables[k] = v[use_server] }
        base_path = server[:url].gsub(/\{(.*?)\}/) { variables[::Regexp.last_match(1).to_sym] }
        URI(base_path).path
      end

      def build_path_string(metadata, openapi_spec, path_parameters)
        template = base_path_from_servers(openapi_spec) + metadata[:path_item][:template]

        path_parameters.each_with_object(template) do |p, path|
          path.gsub!("{#{p[:name]}}", params.fetch(p[:name].to_s).to_s)
        rescue KeyError
          raise ArgumentError, ("`#{p[:name]}`" \
            'parameter key present, but not defined within example group (i. e `it` or `let` block)')
        end
      end

      def build_query_string(query_parameters)
        query_strings = query_parameters.select { |p| params.key?(p[:name]) }
                                        .filter_map { |p| build_query_string_part(p, params[p[:name]]) }
        query_strings.any? ? "?#{query_strings.join('&')}" : ''
      end

      def cleaned_param(param, value)
        raise ArgumentError, "'type' is not supported field for Parameter" unless param[:type].nil?

        CLEAN_PARAM.new(
          escaped_array: (value.to_a.flatten.map { |v| CGI.escape(v.to_s) } if value.respond_to?(:to_a)),
          escaped_name: CGI.escape(param[:name].to_s),
          escaped_value: CGI.escape(value.to_s),
          explode: param[:explode].nil? ? true : param[:explode],
          schema: param[:schema],
          style: param[:style].try(:to_sym) || :form,
          type: param[:schema][:type]&.to_sym
        )
      end

      def build_query_string_part(param, value)
        # NOTE: https://swagger.io/docs/specification/serialization/
        case p = cleaned_param(param, value)
        in { schema: nil } then nil
        in { type: :object, style: :deepObject } then { param[:name] => value }.to_query
        in { type: :object, style: :form, explode: true } then value.to_query
        in { type: :array, explode: true } then p.escaped_array.map { |v| "#{p.escaped_name}=#{v}" }.join('&')
        in { type: :object, style: :form } | { type: :array }
          "#{p.escaped_name}=#{p.escaped_array.join(STYLE_SEPARATORS[p.style])}"
        else "#{p.escaped_name}=#{p.escaped_value}"
        end
      end

      def build_headers(metadata, openapi_spec, header_parameters, example)
        combined = openapi_spec.merge(metadata[:operation])

        tuples = header_parameters.filter_map { |p| [p[:name], headers.fetch(p[:name]).to_s] }
        tuples << ['Accept', headers.fetch('Accept', combined[:produces].first)] if combined[:produces]
        tuples << ['Content-Type', headers.fetch('Content-Type', combined[:consumes].first)] if combined[:consumes]
        tuples << ['Host', example.try(:Host) || combined[:host]] if combined[:host].present?

        # Rails test infrastructure requires rack-formatted headers
        tuples.each_with_object({}) do |pair, headers|
          headers[RACK_FORMATTED_HEADER_KEYS.fetch(pair[0], pair[0])] = pair[1]
        end
      end

      def build_payload(request, parameters, example)
        case request[:headers]['CONTENT_TYPE']
        when nil
          nil
        when 'application/x-www-form-urlencoded', 'multipart/form-data'
          build_form_payload(parameters, example)
        when %r{\Aapplication/([0-9A-Za-z._-]+\+json\z|json\z)}
          build_raw_payload(parameters, example)&.to_json
        else
          build_raw_payload(parameters, example)
        end
      end

      def build_form_payload(parameters, _example)
        # See http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
        # Rather that serializing with the appropriate encoding (e.g. multipart/form-data),
        # Rails test infrastructure allows us to send the values directly as a hash
        # PROS: simple to implement, CONS: serialization/deserialization is bypassed in test
        parameters
          .select { |p| p[:in] == :formData }
          .each_with_object({}) { |p, payload| payload[p[:name]] = params.fetch(p[:name]) }
      end

      def build_raw_payload(parameters, _example)
        body_param = parameters.find { |p| p[:in] == :body } || return
        params.fetch(body_param[:name].to_s)
      rescue KeyError
        raise(MissingParameterError, body_param[:name])
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
