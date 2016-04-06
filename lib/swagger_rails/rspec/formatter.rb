require 'rspec/core/formatters/base_text_formatter'
require 'rails_helper'

module SwaggerRails
  module RSpec

    class Formatter
      ::RSpec::Core::Formatters.register self,
        :example_group_finished,
        :stop

      def initialize(output)
        @output = output
        @swagger_docs = SwaggerRails.swagger_docs

        @output.puts 'Generating Swagger Docs ...'
      end

      def example_group_finished(notification)
        metadata = notification.group.metadata
        return unless metadata.has_key?(:response_code)

        swagger_data = swagger_data_from(metadata)
        swagger_doc = @swagger_docs[metadata[:docs_path]] || @swagger_docs.values.first
        swagger_doc.deep_merge!(swagger_data)
      end

      def stop(notification)
        @swagger_docs.each do |path, doc|
          file_path = File.join(Rails.root, 'config/swagger', path)

          File.open(file_path, 'w') do |file|
            file.write(JSON.pretty_generate(doc))
          end
        end

        @output.puts 'Swagger Doc generated'
      end

      private

      def swagger_data_from(metadata)
        {
          paths: {
            metadata[:path_template] => {
              metadata[:http_verb] => operation_from(metadata)
            }
          }
        }
      end

      def operation_from(metadata)
        metadata.slice(:summary, :consumes, :produces, :parameters).tap do |operation|
          operation[:responses] = {
            metadata[:response_code] => metadata[:response]
          }
        end
      end
    end
  end
end
