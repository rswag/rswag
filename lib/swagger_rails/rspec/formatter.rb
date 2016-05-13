require 'rspec/core/formatters/base_text_formatter'
require 'rails_helper'

module SwaggerRails
  module RSpec

    class Formatter
      ::RSpec::Core::Formatters.register self,
        :example_group_finished,
        :stop

      def initialize(output, config=SwaggerRails.config)
        @output = output
        @swagger_docs = config.swagger_docs
        @swagger_dir_string = config.swagger_dir_string

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
        @swagger_docs.each do |path, doc|
          file_path = File.join(@swagger_dir_string, path)

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
