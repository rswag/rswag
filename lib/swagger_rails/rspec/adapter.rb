require 'swagger_rails/test_visitor'

module SwaggerRails
  module RSpec
    module Adapter

      def path(path_template, &block)
        describe(path_template, path_template: path_template, &block)
      end

      def operation(method, summary=nil, &block)
        operation_metadata = {
          method: method,
          summary: summary,
          parameters: []
        }
        describe(method, operation: operation_metadata, &block)
      end

      def consumes(*mime_types)
        metadata[:operation][:consumes] = mime_types 
      end

      def produces(*mime_types)
        metadata[:operation][:produces] = mime_types 
      end

      def header(name, attributes={})
        parameter(name, 'header', attributes)
      end

      def body(name, attributes={})
        parameter(name, 'body', attributes)
      end

      def parameter(name, location, attributes={})
        parameter_metadata = { name: name.to_s, in: location }.merge(attributes)
        metadata[:operation][:parameters] << parameter_metadata
      end

      def response(status, description, &block)
        response_metadata = { status: status, description: description }
        context(description, response: response_metadata, &block)
      end

      def run_test!
        before do |example|
          SwaggerRails::TestVisitor.instance.act!(
            self, example.metadata[:path_template], example.metadata[:operation]
          )
        end

        it "returns a #{metadata[:response][:status]} status" do |example|
          SwaggerRails::TestVisitor.instance.assert!(
            self, example.metadata[:response]
          )
        end
      end
    end
  end
end

