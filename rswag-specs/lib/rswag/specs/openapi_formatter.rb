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
          doc[:paths]&.each_pair do |_k, v|
            v.each_pair do |_verb, value|
              is_hash = value.is_a?(Hash)
              if is_hash && value[:parameters]
                schema_param = value[:parameters]&.find { |p| (p[:in] == :body || p[:in] == :formData) && p[:schema] }
                mime_list = value[:consumes] || doc[:consumes]
                if value && schema_param && mime_list
                  value[:requestBody] = { content: {} } unless value.dig(:requestBody, :content)
                  value[:requestBody][:required] = true if schema_param[:required]
                  value[:requestBody][:description] = schema_param[:description] if schema_param[:description]
                  examples = value.dig(:request_examples)
                  mime_list.each do |mime|
                    value[:requestBody][:content][mime] = { schema: schema_param[:schema] }
                    if examples
                      value[:requestBody][:content][mime][:examples] ||= {}
                      examples.map do |example|
                        value[:requestBody][:content][mime][:examples][example[:name]] = {
                          summary: example[:summary] || value[:summary],
                          value: example[:value]
                        }
                      end
                    end
                  end
                end

                value[:parameters].reject! { |p| p[:in] == :body || p[:in] == :formData }
              end
              remove_invalid_operation_keys!(value)
            end
          end

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
    end
  end
end
