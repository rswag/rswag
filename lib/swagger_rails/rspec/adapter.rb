require 'swagger_rails/test_visitor'

module SwaggerRails
  module RSpec
    module Adapter

      def path(path_template, &block)
        metadata = {
          path_template: path_template
        }
        describe(path_template, metadata, &block)
      end

      def operation(http_verb, summary=nil, &block)
        metadata = {
          http_verb: http_verb,
          summary: summary,
          parameters: []
        }
        describe(http_verb, metadata, &block)
      end

      [ :get, :post, :patch, :put, :delete, :head ].each do |http_verb|
        define_method(http_verb) do |summary=nil, &block|
          operation(http_verb, summary, &block)
        end
      end

      def consumes(*mime_types)
        metadata[:consumes] = mime_types
      end

      def produces(*mime_types)
        metadata[:produces] = mime_types
      end

      def parameter(name, attributes={})
        metadata[:parameters] << { name: name.to_s }.merge(attributes)
      end

      def response(code, description, &block)
        metadata = {
          response_code: code,
          response: {
            description: description
          }
        }
        context(description, metadata, &block)
      end

      def run_test!
        before do |example|
          SwaggerRails::TestVisitor.instance.submit_request!(self, example.metadata)
        end

        it "returns a #{metadata[:response_code]} status" do |example|
          SwaggerRails::TestVisitor.instance.assert_response!(self, example.metadata)
        end
      end
    end
  end
end

