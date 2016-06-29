require 'rspec/core/formatters'
require 'swagger_helper'

module SwaggerRails
  module RSpec
    class Formatter
      ::RSpec::Core::Formatters.register self,
        :example_group_finished,
        :stop

      def initialize(output)
        @output = output
        @swagger_root = ::RSpec.configuration.swagger_root
        @swagger_docs = ::RSpec.configuration.swagger_docs

        @output.puts 'Generating Swagger Docs ...'
      end

      def example_group_finished(notification)
        metadata = notification.group.metadata
        return unless metadata.has_key?(:response_code)

        swagger_doc = @swagger_docs[metadata[:swagger_doc]] || @swagger_docs.values.first
        swagger_data = swagger_data_from(metadata)
        swagger_doc.deep_merge!(swagger_data)
      end

      def stop(notification)
        @swagger_docs.each do |url_path, doc|
          file_path = File.join(@swagger_root, url_path)

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
        {
          tags: [ find_root_of(metadata)[:description] ] ,
          summary: metadata[:summary],
          consumes: metadata[:consumes],
          produces: metadata[:produces],
          parameters: metadata[:parameters],
          responses: { metadata[:response_code] => metadata[:response] }
        }
      end

      def find_root_of(metadata)
        parent = metadata[:parent_example_group]
        parent.nil? ? metadata : find_root_of(parent)
      end
    end
  end
end
