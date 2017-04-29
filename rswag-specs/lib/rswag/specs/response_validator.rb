require 'active_support/core_ext/hash/slice'
require 'json-schema'
require 'json'
require 'rswag/specs/extended_schema'

module Rswag
  module Specs
    class ResponseValidator

      def initialize(api_metadata, global_metadata)
        @api_metadata = api_metadata
        @global_metadata = global_metadata
      end

      def validate!(response, &block)
        validate_code!(response.code)
        validate_headers!(response.headers)
        validate_body!(response.body, &block)
        block.call(response) if block_given?
      end

      private

      def validate_code!(code)
        if code.to_s != @api_metadata[:response][:code].to_s
          raise UnexpectedResponse, "Expected response code '#{code}' to match '#{@api_metadata[:response][:code]}'"
        end
      end

      def validate_headers!(headers)
        header_schema = @api_metadata[:response][:headers]
        return if header_schema.nil?

        header_schema.keys.each do |header_name|
          raise UnexpectedResponse, "Expected response header #{header_name} to be present" if headers[header_name.to_s].nil?
        end
      end

      def validate_body!(body)
        response_schema = @api_metadata[:response][:schema]
        return if response_schema.nil?

        begin
          validation_schema = response_schema
            .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
            .merge(@global_metadata.slice(:definitions))
          JSON::Validator.validate!(validation_schema, body)
        rescue JSON::Schema::ValidationError => ex
          raise UnexpectedResponse, "Expected response body to match schema: #{ex.message}"
        end
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
