# frozen_string_literal: true

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
        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])
        parameters = expand_parameters(metadata, swagger_doc, example)

        {}.tap do |request|
          add_verb(request, metadata)
          add_path(request, metadata, swagger_doc, parameters, example)
          add_headers(request, metadata, swagger_doc, parameters, example)
          add_payload(request, parameters, example)
        end
      end

      private

      def expand_parameters(metadata, swagger_doc, example)
        operation_params = metadata[:operation][:parameters] || []
        path_item_params = metadata[:path_item][:parameters] || []
        security_params = derive_security_params(metadata, swagger_doc)

        # NOTE: Use of + instead of concat to avoid mutation of the metadata object
        (operation_params + path_item_params + security_params)
          .map { |p| p['$ref'] ? resolve_parameter(p['$ref'], swagger_doc) : p }
          .uniq { |p| p[:name] }
          .reject { |p| p[:required] == false && !headers.key?(p[:name]) && !params.key?(p[:name]) }
      end

      def derive_security_params(metadata, swagger_doc)
        requirements = metadata[:operation][:security] || swagger_doc[:security] || []
        scheme_names = requirements.flat_map(&:keys)
        schemes = security_version(scheme_names, swagger_doc)

        schemes.map do |scheme|
          param = (scheme[:type] == :apiKey) ? scheme.slice(:name, :in) : { name: 'Authorization', in: :header }
          param.merge(type: :string, required: requirements.one?)
        end
      end

      def security_version(scheme_names, swagger_doc)
        if doc_version(swagger_doc).start_with?('2')
          (swagger_doc[:securityDefinitions] || {}).slice(*scheme_names).values
        else # Openapi3
          if swagger_doc.key?(:securityDefinitions)
            ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: securityDefinitions is replaced in OpenAPI3! Rename to components/securitySchemes (in swagger_helper.rb)')
            swagger_doc[:components] ||= { securitySchemes: swagger_doc[:securityDefinitions] }
            swagger_doc.delete(:securityDefinitions)
          end
          components = swagger_doc[:components] || {}
          (components[:securitySchemes] || {}).slice(*scheme_names).values
        end
      end

      def resolve_parameter(ref, swagger_doc)
        key = key_version(ref, swagger_doc)
        definitions = definition_version(swagger_doc)
        raise "Referenced parameter '#{ref}' must be defined" unless definitions && definitions[key]

        definitions[key]
      end

      def key_version(ref, swagger_doc)
        if doc_version(swagger_doc).start_with?('2')
          ref.sub('#/parameters/', '').to_sym
        else # Openapi3
          if ref.start_with?('#/parameters/')
            ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: #/parameters/ refs are replaced in OpenAPI3! Rename to #/components/parameters/')
            ref.sub('#/parameters/', '').to_sym
          else
            ref.sub('#/components/parameters/', '').to_sym
          end
        end
      end

      def definition_version(swagger_doc)
        if doc_version(swagger_doc).start_with?('2')
          swagger_doc[:parameters]
        else # Openapi3
          if swagger_doc.key?(:parameters)
            ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: parameters is replaced in OpenAPI3! Rename to components/parameters (in swagger_helper.rb)')
            swagger_doc[:parameters]
          else
            components = swagger_doc[:components] || {}
            components[:parameters]
          end
        end
      end

      def add_verb(request, metadata)
        request[:verb] = metadata[:operation][:verb]
      end

      def add_path(request, metadata, swagger_doc, parameters, example)
        template = (swagger_doc[:basePath] || '') + metadata[:path_item][:template]

        request[:path] = template.tap do |path_template|
          parameters.select { |p| p[:in] == :path }.each do |p|
            path_template.gsub!("{#{p[:name]}}", params.fetch(p[:name]).to_s)
          end

          parameters.select { |p| p[:in] == :query && params.key?(p[:name]) }.each_with_index do |p, i|
            path_template.concat(i.zero? ? '?' : '&')
            path_template.concat(build_query_string_part(p, params.fetch(p[:name])))
          end
        end
      end

      def build_query_string_part(param, value)
        name = param[:name]
        type = param[:type] || param.dig(:schema, :type)
        return "#{name}=#{value}" unless type&.to_sym == :array

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

      def add_headers(request, metadata, swagger_doc, parameters, example)
        tuples = parameters
          .select { |p| p[:in] == :header }
          .map { |p| [p[:name], headers.fetch(p[:name]).to_s] }

        # Accept header
        produces = metadata[:operation][:produces] || swagger_doc[:produces]
        if produces
          accept = headers.fetch("Accept", produces.first)
          tuples << ['Accept', accept]
        end

        # Content-Type header
        consumes = metadata[:operation][:consumes] || swagger_doc[:consumes]
        if consumes
          content_type = headers.fetch('Content-Type', consumes.first)
          tuples << ['Content-Type', content_type]
        end

        # Rails test infrastructure requires rackified headers
        rackified_tuples = tuples.map do |pair|
          [
            case pair[0]
            when 'Accept' then 'HTTP_ACCEPT'
            when 'Content-Type' then 'CONTENT_TYPE'
            when 'Authorization' then 'HTTP_AUTHORIZATION'
            else pair[0]
            end,
            pair[1]
          ]
        end

        request[:headers] = Hash[rackified_tuples]
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
          .map { |p| [p[:name], params.fetch(p[:name])] }
        Hash[tuples]
      end

      def build_json_payload(parameters)
        body_param = parameters.select { |p| p[:in] == :body }.first
        body_param ? params.fetch(body_param[:name]).to_json : nil
      end

      def doc_version(doc)
        doc[:openapi] || doc[:swagger] || '3'
      end

    end
  end
end
