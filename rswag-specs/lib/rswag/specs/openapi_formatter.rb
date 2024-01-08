# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'rspec/core/formatters/base_text_formatter'
require 'openapi_helper'

module Rswag
  module Specs
    class OpenapiFormatter < ::RSpec::Core::Formatters::BaseTextFormatter
      ::RSpec::Core::Formatters.register self, :example_group_finished, :stop

      def initialize(output, config = Rswag::Specs.config)
        @output = output
        @config = config

        @output.puts 'Generating OpenAPI spec...'
      end

      def example_group_finished(notification)
        metadata = notification.group.metadata
        # metadata[:document] has to be explicitly false to skip generating docs
        return if metadata[:document] == false
        return unless metadata.key?(:response)

        openapi_spec = @config.get_openapi_spec(metadata[:openapi_spec])
        if !doc_version(openapi_spec).start_with?('3')
          raise ConfigurationError, "Unsupported OpenAPI version"
        end

        # This is called multiple times per file!
        # metadata[:operation] is also re-used between examples within file
        # therefore be careful NOT to modify its content here.
        upgrade_request_type!(metadata)
        upgrade_response_produces!(openapi_spec, metadata)

        openapi_spec.deep_merge!(metadata_to_openapi(metadata))
      end

      def stop(_notification = nil)
        @config.openapi_specs.each do |url_path, doc|
          parse_parameters(doc)

          file_path = File.join(@config.openapi_root, url_path)
          dirname = File.dirname(file_path)
          FileUtils.mkdir_p dirname unless File.exist?(dirname)

          File.open(file_path, 'w') do |file|
            file.write(pretty_generate(doc))
          end

          @output.puts "OpenAPI doc generated at #{file_path}"
        end
      end

      private

      def pretty_generate(doc)
        if @config.openapi_format == :yaml
          clean_doc = yaml_prepare(doc)
          YAML.dump(clean_doc)
        else # config errors are thrown in 'def openapi_format', no throw needed here
          JSON.pretty_generate(doc)
        end
      end

      def yaml_prepare(doc)
        json_doc = JSON.pretty_generate(doc)
        JSON.parse(json_doc)
      end

      def metadata_to_openapi(metadata)
        response_code = metadata[:response][:code]
        response = metadata[:response].reject { |k, _v| k == :code }

        verb = metadata[:operation][:verb]
        operation = metadata[:operation]
          .reject { |k, _v| k == :verb }
          .merge(responses: { response_code => response })

        path_template = metadata[:path_item][:template]
        path_item = metadata[:path_item]
          .reject { |k, _v| k == :template }
          .merge(verb => operation)

        { paths: { path_template => path_item } }
      end

      def doc_version(doc)
        doc[:openapi]
      end

      def upgrade_response_produces!(openapi_spec, metadata)
        # Accept header
        mime_list = Array(metadata[:operation][:produces] || openapi_spec[:produces])
        target_node = metadata[:response]
        upgrade_content!(mime_list, target_node)
        metadata[:response].delete(:schema)
      end

      def upgrade_content!(mime_list, target_node)
        schema = target_node[:schema]
        return if mime_list.empty? || schema.nil?

        target_node[:content] ||= {}
        mime_list.each do |mime_type|
          # TODO: upgrade to have content-type specific schema
          (target_node[:content][mime_type] ||= {}).merge!(schema: schema)
        end
      end

      def upgrade_request_type!(metadata)
        # No deprecation here as it seems valid to allow type as a shorthand
        operation_nodes = metadata[:operation][:parameters] || []
        path_nodes = metadata[:path_item][:parameters] || []
        header_node = metadata[:response][:headers] || {}

        (operation_nodes + path_nodes + [header_node]).each do |node|
          if node && node[:type] && node[:schema].nil?
            node[:schema] = { type: node[:type] }
            node.delete(:type)
          end
        end
      end

      def remove_invalid_operation_keys!(value)
        return unless value.is_a?(Hash)

        value.delete(:consumes) if value[:consumes]
        value.delete(:produces) if value[:produces]
        value.delete(:request_examples) if value[:request_examples]
      end

      def parse_parameters(doc)
        doc[:paths]&.each_pair do |_k, path|
          path.each_pair do |_verb, endpoint|
            is_hash = endpoint.is_a?(Hash)
            if is_hash && endpoint[:parameters]
              mime_list = endpoint[:consumes] || doc[:consumes]
              parse_endpoint(endpoint, mime_list) if mime_list
            end
            remove_invalid_operation_keys!(endpoint)
          end
        end
      end

      def parse_endpoint(endpoint, mime_list)
        parameters = endpoint[:parameters]
        # There can only be 1 body parameter in Swagger 2.0, so while in OAS3 we interpret
        # body parameters as formData, only consider the first body we encounter.
        schema_param = parameters.find { |p| (p[:in] == :body) && p[:schema] }
        parse_body_parameter(endpoint, schema_param, mime_list) if schema_param

        # But there can be any number of formData
        parameters.select { |p| (p[:in] == :formData) && p[:schema] }.each do |schema_param|
          parse_parameter_schema(endpoint, schema_param, mime_list)
        end

        parameters.reject! { |p| p[:in] == :body || p[:in] == :formData }
      end

      def add_request_body(endpoint)
        return if endpoint.dig(:requestBody, :content)
        endpoint[:requestBody] = { content: {} }
      end

      def parse_body_parameter(endpoint, parameter, mime_list)
        add_request_body(endpoint)
        # If a parameter in `body` exists use its description (there is only ever 1)
        endpoint[:requestBody][:description] = parameter[:description] if parameter[:description]

        parse_parameter_schema(endpoint, parameter, mime_list)
      end

      def parse_parameter_schema(endpoint, parameter, mime_list)
        # Only add if there are any body parameters and not already defined
        add_request_body(endpoint)

        mime_list.each do |mime|
          endpoint[:requestBody][:content][mime] ||= {}
          mime_config = endpoint[:requestBody][:content][mime]
          set_parameter_schema(parameter)
          convert_file_parameter(parameter)
          # Only parse parameters if there has not already been a reference object set
          if !mime_config[:schema] || mime_config.dig(:schema, :properties)
            set_mime_config(mime_config, parameter)
            set_mime_examples(mime_config, endpoint)
          end
        end

        set_request_body_required(endpoint, mime_list)
      end

      # FIXME: If any are `required` then the body is set to `required` but this assumption may not hold in reality as
      # you could have optional body, but if body is provided then some properties are required.
      # Also could just parse this info at time of parsing parameters
      def set_request_body_required(endpoint, mime_list)
        required = mime_list.any? do |mime|
          mime_config = endpoint[:requestBody][:content][mime]
          mime_config.any? do |_mime, config|
            config[:required] || config.dig(:schema, :required) || config[:properties]&.any? { |_k, s| s[:required] }
          end
        end
        endpoint[:requestBody][:required] = true if required
      end

      def set_parameter_schema(parameter)
        parameter[:schema] ||= {}
        parameter[:schema][:required] = true if parameter[:required]
        parameter[:schema][:description] = parameter[:description] if parameter[:description]
      end

      def convert_file_parameter(parameter)
        if parameter[:schema][:type] == :file
          parameter[:schema][:type] = :string
          parameter[:schema][:format] = :binary
        end
      end

      def set_mime_config(mime_config, parameter)
        mime_config[:schema] ||= parameter[:name] ? {type: :object, properties: {}} : parameter[:schema]
        if parameter[:name]
          mime_config[:schema][:properties][parameter[:name]] = parameter[:schema]
          set_mime_encoding(mime_config, parameter)
        end
      end

      def set_mime_encoding(mime_config, parameter)
        return unless parameter[:encoding]
        encoding = parameter[:encoding].dup
        encoding[:contentType] = encoding[:contentType].join(",") if encoding[:contentType].is_a?(Array)
        mime_config[:encoding] ||= {}
        mime_config[:encoding][parameter[:name]] = encoding
      end

      def set_mime_examples(mime_config, endpoint)
        examples = endpoint[:request_examples]
        return unless examples
        examples.each do |example|
          mime_config[:examples] ||= {}
          mime_config[:examples][example[:name]] = {
            summary: example[:summary] || endpoint[:summary],
            value: example[:value]
          }
        end
      end
    end
  end
end
