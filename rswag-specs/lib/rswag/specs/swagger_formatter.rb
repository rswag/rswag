# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'rspec/core/formatters/base_text_formatter'
require 'swagger_helper'

module Rswag
  module Specs
    class SwaggerFormatter < ::RSpec::Core::Formatters::BaseTextFormatter
      ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: Support for Ruby 2.6 will be dropped in v3.0') if RUBY_VERSION.start_with? '2.6'

      if RSPEC_VERSION > 2
        ::RSpec::Core::Formatters.register self, :example_group_finished, :stop
      else
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: Support for RSpec 2.X will be dropped in v3.0')
      end

      def initialize(output, config = Rswag::Specs.config)
        @output = output
        @config = config

        @output.puts 'Generating Swagger docs ...'
      end

      def example_group_finished(notification)
        metadata = if RSPEC_VERSION > 2
          notification.group.metadata
        else
          notification.metadata
        end

        # !metadata[:document] won't work, since nil means we should generate
        # docs.
        return if metadata[:document] == false
        return unless metadata.key?(:response)

        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])

        unless doc_version(swagger_doc).start_with?('2')
          # This is called multiple times per file!
          # metadata[:operation] is also re-used between examples within file
          # therefore be careful NOT to modify its content here.
          upgrade_request_type!(metadata)
          upgrade_servers!(swagger_doc)
          upgrade_oauth!(swagger_doc)
          upgrade_response_produces!(swagger_doc, metadata)
        end

        swagger_doc.deep_merge!(metadata_to_swagger(metadata))
      end

      def stop(_notification = nil)
        @config.swagger_docs.each do |url_path, doc|
          unless doc_version(doc).start_with?('2')
            doc[:paths]&.each_pair do |_k, path|
              path.each_pair do |_verb, endpoint|
                is_hash = endpoint.is_a?(Hash)
                if is_hash && endpoint[:parameters]
                  mime_list = endpoint[:consumes] || doc[:consumes]
                  parse_parameters(endpoint, mime_list) if mime_list
                end
                remove_invalid_operation_keys!(endpoint)
              end
            end
          end

          file_path = File.join(@config.swagger_root, url_path)
          dirname = File.dirname(file_path)
          FileUtils.mkdir_p dirname unless File.exist?(dirname)

          File.open(file_path, 'w') do |file|
            file.write(pretty_generate(doc))
          end

          @output.puts "Swagger doc generated at #{file_path}"
        end
      end

      private

      def pretty_generate(doc)
        if @config.swagger_format == :yaml
          clean_doc = yaml_prepare(doc)
          YAML.dump(clean_doc)
        else # config errors are thrown in 'def swagger_format', no throw needed here
          JSON.pretty_generate(doc)
        end
      end

      def yaml_prepare(doc)
        json_doc = JSON.pretty_generate(doc)
        JSON.parse(json_doc)
      end

      def metadata_to_swagger(metadata)
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
        doc[:openapi] || doc[:swagger] || '3'
      end

      def upgrade_response_produces!(swagger_doc, metadata)
        # Accept header
        mime_list = Array(metadata[:operation][:produces] || swagger_doc[:produces])
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

      def upgrade_servers!(swagger_doc)
        return unless swagger_doc[:servers].nil? && swagger_doc.key?(:schemes)

        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: schemes, host, and basePath are replaced in OpenAPI3! Rename to array of servers[{url}] (in swagger_helper.rb)')

        swagger_doc[:servers] = { urls: [] }
        swagger_doc[:schemes].each do |scheme|
          swagger_doc[:servers][:urls] << scheme + '://' + swagger_doc[:host] + swagger_doc[:basePath]
        end

        swagger_doc.delete(:schemes)
        swagger_doc.delete(:host)
        swagger_doc.delete(:basePath)
      end

      def upgrade_oauth!(swagger_doc)
        # find flow in securitySchemes (securityDefinitions will have been re-written)
        schemes = swagger_doc.dig(:components, :securitySchemes)
        return unless schemes&.any? { |_k, v| v.key?(:flow) }

        schemes.each do |name, v|
          next unless v.key?(:flow)

          ActiveSupport::Deprecation.warn("Rswag::Specs: WARNING: securityDefinitions flow is replaced in OpenAPI3! Rename to components/securitySchemes/#{name}/flows[] (in swagger_helper.rb)")
          flow = swagger_doc[:components][:securitySchemes][name].delete(:flow).to_s
          if flow == 'accessCode'
            ActiveSupport::Deprecation.warn("Rswag::Specs: WARNING: securityDefinitions accessCode is replaced in OpenAPI3! Rename to clientCredentials (in swagger_helper.rb)")
            flow = 'authorizationCode'
          end
          if flow == 'application'
            ActiveSupport::Deprecation.warn("Rswag::Specs: WARNING: securityDefinitions application is replaced in OpenAPI3! Rename to authorizationCode (in swagger_helper.rb)")
            flow = 'clientCredentials'
          end
          flow_elements = swagger_doc[:components][:securitySchemes][name].except(:type).each_with_object({}) do |(k, _v), a|
            a[k] = swagger_doc[:components][:securitySchemes][name].delete(k)
          end
          swagger_doc[:components][:securitySchemes][name].merge!(flows: { flow => flow_elements })
        end
      end

      def remove_invalid_operation_keys!(value)
        return unless value.is_a?(Hash)

        value.delete(:consumes) if value[:consumes]
        value.delete(:produces) if value[:produces]
        value.delete(:request_examples) if value[:request_examples]
        value[:parameters].each { |p| p.delete(:getter) } if value[:parameters]
      end

      def parse_parameters(endpoint, mime_list)
        parameters = endpoint[:parameters]
        # There can only be 1 body!
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
        set_request_body_required(endpoint, parameter)

        mime_list.each do |mime|
          endpoint[:requestBody][:content][mime] ||= {}
          mime_config = endpoint[:requestBody][:content][mime]
          set_parameter_schema(parameter)
          set_mime_config(mime_config, parameter)
          set_mime_examples(mime_config, endpoint)
        end
      end

      # FIXME: If any are `required` then the body is set to `required` but this assumption may not hold in reality as
        # you could have optional body, but if body is provided then some properties are required.
      def set_request_body_required(endpoint, parameter)
        required = parameter[:required] || parameter.dig(:schema, :required)
        endpoint[:requestBody][:required] = true if required
      end

      def set_parameter_schema(parameter)
        parameter[:schema] ||= {}
        parameter[:schema][:required] = true if parameter[:required]
        parameter[:schema][:description] = parameter[:description] if parameter[:description]
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
