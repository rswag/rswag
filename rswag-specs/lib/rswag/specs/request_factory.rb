# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/conversions'
require 'json'

require_relative './query_parameter'

# TODO: Move the validation & inserting of defaults to its own section
# Right now everything is intermingled so everything is checking for nils and missing keys
# maybe another class so we can do stuff like `@request_schema.path` & `@request_schema.headers`?

module Rswag
  module Specs
    class RequestFactory # rubocop:disable Metrics/ClassLength
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
        request = {
          verb: metadata[:operation][:verb],
          path: build_path_string(metadata, openapi_spec, parameter_groups[:path]) +
                build_query_string(parameter_groups[:query]),
          headers: build_headers(metadata, openapi_spec, parameter_groups[:header], example)
        }
        request[:payload] = case request[:headers]['CONTENT_TYPE']
                            when nil then nil
                            when 'application/x-www-form-urlencoded', 'multipart/form-data'
                              build_form_payload(parameter_groups[:formData])
                            when %r{\Aapplication/([0-9A-Za-z._-]+\+json\z|json\z)}
                              build_raw_payload(parameter_groups[:body])&.to_json
                            else
                              build_raw_payload(parameter_groups[:body])
                            end
        request
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
        query_strings = query_parameters.filter_map { |p| QueryParameter.new(p, params[p[:name]]).to_query }
        query_strings.any? ? "?#{query_strings.join('&')}" : ''
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

      def build_form_payload(form_parameters)
        # See http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
        # Rather that serializing with the appropriate encoding (e.g. multipart/form-data),
        # Rails test infrastructure allows us to send the values directly as a hash
        # PROS: simple to implement, CONS: serialization/deserialization is bypassed in test
        form_parameters
          .each_with_object({}) { |p, payload| payload[p[:name]] = params.fetch(p[:name]) }
      end

      def build_raw_payload(body_parameters)
        body_param = body_parameters.first || return
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
