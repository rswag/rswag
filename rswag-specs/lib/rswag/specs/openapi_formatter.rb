# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'rspec/core/formatters/base_text_formatter'
require 'openapi_helper'
require_relative './mime_config'

module Rswag
  module Specs
    class OpenapiFormatter < ::RSpec::Core::Formatters::BaseTextFormatter # rubocop:disable Metrics/ClassLength
      ::RSpec::Core::Formatters.register self, :example_group_finished, :stop

      INVALID_OPERATION_KEYS = %i[consumes produces request_examples].freeze

      def initialize(output, config = Rswag::Specs.config)
        super(output)
        @config = config

        @output.puts 'Generating OpenAPI spec...'
      end

      def example_group_finished(notification)
        metadata = notification.group.metadata
        # metadata[:document] has to be explicitly false to skip generating docs
        return if metadata[:document] == false
        return unless metadata.key?(:response)

        openapi_spec = @config.get_openapi_spec(metadata[:openapi_spec])
        raise ConfigurationError, 'Unsupported OpenAPI version' unless openapi_spec[:openapi].start_with?('3')

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
          clean_doc = JSON.parse(JSON.pretty_generate(doc))
          YAML.dump(clean_doc)
        else # config errors are thrown in 'def openapi_format', no throw needed here
          JSON.pretty_generate(doc)
        end
      end

      def metadata_to_openapi(metadata)
        response = metadata[:response].reject { |k, _v| k == :code }
        operation = metadata[:operation]
                    .reject { |k, _v| k == :verb }
                    .merge(responses: { metadata[:response][:code] => response })

        path_template = metadata[:path_item][:template]
        path_item = metadata[:path_item]
                    .reject { |k, _v| k == :template }
                    .merge(metadata[:operation][:verb] => operation)

        { paths: { path_template => path_item } }
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
        nodes = [
          *metadata[:operation][:parameters],
          *metadata[:path_item][:parameters],
          *metadata[:response][:headers]&.values
        ]

        nodes.each do |node|
          node[:schema] ||= { type: node.delete(:type) } if node&.dig(:type)
        end
      end

      def parse_parameters(doc)
        doc[:paths]&.each_pair do |_k, path|
          path.each_pair do |_verb, endpoint|
            next unless endpoint.is_a?(Hash)

            parse_endpoint(endpoint, endpoint[:consumes] || doc[:consumes]) if endpoint[:parameters]
            INVALID_OPERATION_KEYS.each { |k| endpoint.delete(k) }
          end
        end
      end

      def parse_endpoint(endpoint, mime_list)
        parameters = endpoint[:parameters]

        # Parse any parameters
        parameters.each do |parameter|
          add_to_schema(parameter)
          convert_file_parameter(parameter)
          parse_enum(parameter)
        end

        # Parse parameters that are body parameters:
        parameters.select { |p| %i[formData body].include?(p[:in]) }.each do |parameter|
          parse_form_data_or_body_parameter(endpoint, parameter, mime_list)
          parameters.delete(parameter) # "consume" parameters that will end up in response body
        end
      end

      def add_to_schema(parameter)
        # It might be that the schema has a required attribute as a boolean, but it must be an array, hence remove it
        # and simply mark the parameter as required, which will be processed later.
        schema = parameter[:schema] || {}
        parameter[:required] = schema.delete(:required) if schema[:required] == true
        #  Also parameters currently can be defined with a datatype (`type:`)
        #  but this should be in `schema:` in the output.
        schema[:type] = parameter.delete(:type) if parameter.key?(:type)
        parameter[:schema] = schema if schema.present?
      end

      def parse_form_data_or_body_parameter(endpoint, parameter, mime_list)
        unless mime_list
          raise ConfigurationError,
                'A body or form data parameters are specified without a Media Type for the content'
        end

        # Only add requestBody if there are any body parameters and not already defined
        endpoint[:requestBody] = { content: {} } unless endpoint.dig(:requestBody, :content)

        # If a description is provided for the parameter, it should be moved to the schema description
        desc = parameter.delete(:description)
        parameter[:schema][:description] = desc if desc

        mime_list.each { |mime| MimeConfig.new(endpoint, mime, parameter).prepare }
      end

      def convert_file_parameter(parameter)
        return unless parameter.dig(:schema, :type) == :file

        parameter[:schema].merge!(type: :string, format: :binary)
      end

      def parse_enum(parameter)
        enum = parameter.delete(:enum) || return
        parameter[:schema] ||= {}
        parameter[:schema][:enum] = enum.is_a?(Hash) ? enum.keys.map(&:to_s) : enum
        parameter[:description] = generate_enum_description(parameter, enum) if enum.is_a?(Hash)
      end

      def generate_enum_description(param, enum)
        enum_descriptions = enum.map { |k, v| "* `#{k}` #{v}" }
        ["#{param[:description]}:", enum_descriptions, ''].join("\n ")
      end
    end
  end
end
