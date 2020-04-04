require 'active_support/core_ext/hash/deep_merge'
require 'rspec/core/formatters/base_text_formatter'
require 'swagger_helper'

module Rswag
  module Specs
    class SwaggerFormatter < ::RSpec::Core::Formatters::BaseTextFormatter

      # NOTE: rspec 2.x support
      if RSPEC_VERSION > 2
        ::RSpec::Core::Formatters.register self, :example_group_finished, :stop
      end

      def initialize(output, config = Rswag::Specs.config)
        @output = output
        @config = config

        @output.puts 'Generating Swagger docs ...'
      end

      def example_group_finished(notification)
        # NOTE: rspec 2.x support
        if RSPEC_VERSION > 2
          metadata = notification.group.metadata
        else
          metadata = notification.metadata
        end

        # !metadata[:document] won't work, since nil means we should generate
        # docs.
        return if metadata[:document] == false
        return unless metadata.has_key?(:response)

        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])
        swagger_doc.deep_merge!(metadata_to_swagger(metadata))
      end

      def stop(notification=nil)
        @config.swagger_docs.each do |url_path, doc|
          file_path = File.join(@config.swagger_root, url_path)
          dirname = File.dirname(file_path)
          FileUtils.mkdir_p dirname unless File.exists?(dirname)

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
        clean_doc = JSON.parse(json_doc)
      end

      def metadata_to_swagger(metadata)
        response_code = metadata[:response][:code]
        response = metadata[:response].reject { |k,v| k == :code }

        verb = metadata[:operation][:verb]
        operation = metadata[:operation]
          .reject { |k,v| k == :verb }
          .merge(responses: { response_code => response })

        path_template = metadata[:path_item][:template]
        path_item = metadata[:path_item]
          .reject { |k,v| k == :template }
          .merge(verb => operation)

        { paths: { path_template => path_item } }
      end
    end
  end
end
