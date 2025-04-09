# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/conversions'
require 'json'

require_relative './query_parameter'
require_relative './path_parameter'

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
      attr_accessor :example, :metadata, :param_values, :headers

      def initialize(metadata, example, config = ::Rswag::Specs.config)
        @config = config
        @example = example
        @metadata = metadata
        @param_values = example.respond_to?(:request_params) ? example.request_params : {}
        @headers = example.respond_to?(:request_headers) ? example.request_headers : {}
      end

      def build_request
        openapi_spec = @config.get_openapi_spec(metadata[:openapi_spec])
        parameter_definitions = expand_definitions(metadata, openapi_spec, example)
        definition_groups = parameter_definitions.group_by { |d| d[:in] }.reverse_merge(EMPTY_PARAMETER_GROUPS)
        request = {
          verb: metadata[:operation][:verb],
          path: build_path_string(metadata, openapi_spec, definition_groups[:path]) +
                build_query_string(definition_groups[:query]),
          headers: build_headers(metadata, openapi_spec, definition_groups[:header], example)
        }
        request[:payload] = case request[:headers]['CONTENT_TYPE']
                            when nil then nil
                            when 'application/x-www-form-urlencoded', 'multipart/form-data'
                              build_form_payload(definition_groups[:formData])
                            when %r{\Aapplication/([0-9A-Za-z._-]+\+json\z|json\z)}
                              build_raw_payload(definition_groups[:body])&.to_json
                            else
                              build_raw_payload(definition_groups[:body])
                            end
        request
      end

      private

      def expand_definitions(metadata, openapi_spec, _example)
        expandable_definitions = [
          *metadata[:operation][:parameters],
          *metadata[:path_item][:parameters],
          *derive_security_definitions(metadata, openapi_spec)
        ]

        expandable_definitions
          .map { |d| d['$ref'] ? resolve_parameter(d['$ref'], openapi_spec) : d }
          .uniq { |d| d[:name] }
          .reject { |d| d[:required] == false && !headers.key?(d[:name]) && !param_values.key?(d[:name]) }
      end

      def derive_security_definitions(metadata, openapi_spec)
        requirements = metadata[:operation][:security] || openapi_spec[:security] || []
        scheme_names = requirements.flat_map(&:keys)
        schemes = (openapi_spec.dig(:components, :securitySchemes) || {}).slice(*scheme_names).values

        schemes.map do |scheme|
          definition = scheme[:type] == :apiKey ? scheme.slice(:name, :in) : { name: 'Authorization', in: :header }
          definition.merge(schema: { type: :string }, required: requirements.one?)
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

      def build_path_string(metadata, openapi_spec, path_definitions)
        template = base_path_from_servers(openapi_spec) + metadata[:path_item][:template]
        path_definitions.each_with_object(template) do |d, path|
          PathParameter.new(d, param_values[d[:name]]).sub_into_template!(path)
        end
      end

      def build_query_string(query_definitions)
        query_strings = query_definitions.filter_map { |d| QueryParameter.new(d, param_values[d[:name]]).to_query }
        query_strings.any? ? "?#{query_strings.join('&')}" : ''
      end

      def build_headers(metadata, openapi_spec, header_definitions, example)
        combined = openapi_spec.merge(metadata[:operation])

        tuples = header_definitions.filter_map { |d| [d[:name], headers.fetch(d[:name]).to_s] }
        tuples << ['Accept', headers.fetch('Accept', combined[:produces].first)] if combined[:produces]
        tuples << ['Content-Type', headers.fetch('Content-Type', combined[:consumes].first)] if combined[:consumes]
        tuples << ['Host', example.try(:Host) || combined[:host]] if combined[:host].present?

        # Rails test infrastructure requires rack-formatted headers
        tuples.each_with_object({}) do |pair, headers|
          headers[RACK_FORMATTED_HEADER_KEYS.fetch(pair[0], pair[0])] = pair[1]
        end
      end

      def build_form_payload(form_definitions)
        # See http://seejohncode.com/2012/04/29/quick-tip-testing-multipart-uploads-with-rspec/
        # Rather that serializing with the appropriate encoding (e.g. multipart/form-data),
        # Rails test infrastructure allows us to send the values directly as a hash
        # PROS: simple to implement, CONS: serialization/deserialization is bypassed in test
        form_definitions
          .each_with_object({}) { |d, payload| payload[d[:name]] = param_values.fetch(d[:name]) }
      end

      def build_raw_payload(body_definitions)
        body_param = body_definitions.first || return
        param_values.fetch(body_param[:name].to_s)
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
