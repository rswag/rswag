require 'json-schema'

module Rswag
  module Specs
    class ResponseValidator

      def initialize(api_metadata, global_metadata)
        @api_metadata = api_metadata
        @global_metadata = global_metadata
      end

      def validate!(response)
        validate_code!(response.code)
        validate_body!(response.body)
      end

      private

      def validate_code!(code)
        if code.to_s != @api_metadata[:response][:code].to_s
          raise UnexpectedResponse, "Expected response code '#{code}' to match '#{@api_metadata[:response][:code]}'"
        end
      end

      def validate_body!(body)
        schema = @api_metadata[:response][:schema]
        return if schema.nil?
        begin
          JSON::Validator.validate!(schema.merge(@global_metadata), body)
        rescue JSON::Schema::ValidationError => ex
          raise UnexpectedResponse, "Expected response body to match schema: #{ex.message}" 
        end
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
