# frozen_string_literal: true

require 'active_support/core_ext/hash/slice'
require 'json-schema'
require 'json'
require 'rswag/specs/extended_schema'

module Rswag
  module Specs
    class ResponseValidator
      def initialize(config = ::Rswag::Specs.config)
        @config = config
      end

      def validate!(metadata, response)
        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])

        validate_code!(metadata, response)
        validate_headers!(metadata, response.headers)
        validate_body!(metadata, swagger_doc, response.body)
      end

      private

      def validate_code!(metadata, response)
        expected = metadata[:response][:code].to_s
        if response.code != expected
          raise UnexpectedResponse,
            "Expected response code '#{response.code}' to match '#{expected}'\n" \
              "Response body: #{response.body}"
        end
      end

      def validate_headers!(metadata, headers)
        expected = (metadata[:response][:headers] || {}).keys
        expected.each do |name|
          raise UnexpectedResponse, "Expected response header #{name} to be present" if headers[name.to_s].nil?
        end
      end

      def validate_body!(metadata, swagger_doc, body)
        response_schema = metadata[:response][:schema]
        return if response_schema.nil?
        ## OA3
        # test_schemas = extract_schemas(metadata)
        # return if test_schemas.nil? || test_schemas.empty?

        # OA3
        # components = swagger_doc[:components] || {}
        # components_schemas = { components: { schemas: components[:schemas] } }

        # validation_schema = test_schemas[:schema] # response_schema
        validation_schema = response_schema
          .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
          .merge(swagger_doc.slice(:definitions))
          ## OA3
          # .merge(components_schemas)

        errors = JSON::Validator.fully_validate(validation_schema, body)
        raise UnexpectedResponse, "Expected response body to match schema: #{errors[0]}" if errors.any?
      end
      ## OA3
      # def extract_schemas(metadata)
      #   metadata[:operation] = {produces: []} if metadata[:operation].nil?
      #   produces = Array(metadata[:operation][:produces])

      #   producer_content = produces.first || 'application/json'
      #   response_content = metadata[:response][:content] || {producer_content => {}}
      #   response_content[producer_content]
      # end
    end

    class UnexpectedResponse < StandardError; end
  end
end
