# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'swagger_helper'

module OpenApi
  module Rswag
    module Specs
      class SwaggerFormatter
        # NOTE: rspec 2.x support
        if RSPEC_VERSION > 2
          ::RSpec::Core::Formatters.register self, :example_group_finished, :stop
        end

        def initialize(output, config = ::OpenApi::Rswag::Specs.config)
          @output = output
          @config = config

          @output.puts 'Generating Swagger docs ...'
        end

        def example_group_finished(notification)
          # NOTE: rspec 2.x support
          metadata = if RSPEC_VERSION > 2
                       notification.group.metadata
                     else
                       notification.metadata
                     end

          return unless metadata.key?(:response)

          swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])
          swagger_doc.deep_merge!(metadata_to_swagger(metadata))
        end

        def stop(_notification = nil)
          @config.swagger_docs.each do |url_path, doc|
            # remove 2.0 parameters
            doc[:paths]&.each_pair do |_k, v|
              v.each_pair do |_verb, value|
                is_hash = value.is_a?(Hash)
                if is_hash && value.dig(:parameters)
                  schema_param = value&.dig(:parameters)&.find{|p| p[:in] == :body && p[:schema] }
                  if value &&  schema_param && value&.dig(:requestBody, :content, 'application/json')
                    value[:requestBody][:content]['application/json'].merge!(schema: schema_param[:schema])
                  end

                  value[:parameters].reject! { |p| p[:in] == :body || p[:in] == :formData }
                  value[:parameters].each { |p| p.delete(:type) }
                  value[:headers].each { |p| p.delete(:type)}  if value[:headers]
                end

                value.delete(:consumes) if is_hash && value.dig(:consumes)
                value.delete(:produces) if is_hash && value.dig(:produces)
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
          content_type = metadata[:response][:content].present? ? metadata[:response][:content].keys.first : 'application/json'

          # need to merge in to response
          if response[:examples]&.dig(content_type)
            example = response[:examples].dig(content_type).dup
            schema = response.dig(:content, content_type, :schema)
            new_hash = {example: example}
            new_hash[:schema] = schema if schema
            response.merge!(content: { content_type => new_hash })
            response.delete(:examples)
          end

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
      end
    end
  end
end
