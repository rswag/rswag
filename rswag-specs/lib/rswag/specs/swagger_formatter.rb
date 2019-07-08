# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'swagger_helper'

module Rswag
  module Specs
    class SwaggerFormatter
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
          doc[:paths].each_pair do |_k, v|
            v.each_pair do |_verb, value|
              if value&.dig(:parameters)
                value[:parameters].reject! { |p| p[:in] == :body }
              end
            end
          end
          
          file_path = File.join(@config.swagger_root, url_path)
          dirname = File.dirname(file_path)
          FileUtils.mkdir_p dirname unless File.exist?(dirname)

          File.open(file_path, 'w') do |file|
            file.write(JSON.pretty_generate(doc))
          end

          @output.puts "Swagger doc generated at #{file_path}"
        end
      end

      private

      def metadata_to_swagger(metadata)
        response_code = metadata[:response][:code]
        response = metadata[:response].reject { |k, _v| k == :code }

        # need to merge in to response
        if response[:examples]&.dig('application/json')
          example = response[:examples].dig('application/json').dup
          response.merge!(content: { 'application/json' => { example: example } })
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
