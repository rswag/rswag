require 'rspec/core/formatters/base_text_formatter'

module SwaggerRails
  module RSpec

    class Formatter
      ::RSpec::Core::Formatters.register self,
        :example_group_started,
        :example_group_finished,
        :stop

      def initialize(output)
        @output = output
        @swagger_docs = {}
        @group_level = 0

        @output.puts 'Generating Swagger Docs ...'
      end

      def example_group_started(notification)
        @group_level += 1
        group = notification.group
        metadata = group.metadata

        @output.puts "group_level: #{@group_level}"
        @output.puts metadata.slice(:doc, :path_template, :operation, :response).inspect
      end

      def example_group_finished(notification)
        @group_level -= 1
      end

      def stop(notification)
      end
    end
  end
end
