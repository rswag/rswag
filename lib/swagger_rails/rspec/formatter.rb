require 'rspec/core/formatters'
require 'swagger_helper'
require 'swagger_rails/rspec/api_metadata'

module SwaggerRails
  module RSpec
    class Formatter
      ::RSpec::Core::Formatters.register self,
        :example_finished,
        :example_group_started,
        :example_group_finished,
        :stop

      def initialize(output)
        @output = output
        @swagger_root = ::RSpec.configuration.swagger_root
        @swagger_docs = ::RSpec.configuration.swagger_docs

        @output.puts 'Generating Swagger Docs ...'
      end

      def example_group_started(notification)
        @examples = nil
      end

      def example_finished(notification)
        # TODO we should report errors so you know if you're trying to generate
        # docs from failing specs
        mime_type = notification.example.metadata[:response_mime_type]
        body = notification.example.metadata[:response_body]

        if mime_type && body
          if mime_type == 'application/json'
            begin
              body = JSON.parse(body)
            rescue JSON::ParserError => e
            end
          end

          @examples = { mime_type => body }
        end
      end

      def example_group_finished(notification)
        if notification.group.metadata[:response] && @examples
          notification.group.metadata[:response][:examples] = @examples
        end
        metadata = APIMetadata.new(notification.group.metadata)
        return unless metadata.response_example?

        swagger_doc = @swagger_docs[metadata.swagger_doc] || @swagger_docs.values.first
        swagger_doc.deep_merge!(metadata.swagger_data)
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
    end
  end
end
