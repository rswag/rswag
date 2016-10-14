module Rswag
  module Specs
    module ExampleGroupHelpers

      def path(template, &block)
        api_metadata = { path_item: { template: template } }
        describe(template, api_metadata, &block)
      end

      [ :get, :post, :patch, :put, :delete, :head ].each do |verb|
        define_method(verb) do |summary, &block|
          api_metadata = { operation: { verb: verb, summary: summary } }
          describe(verb, api_metadata, &block)
        end
      end

      [ :operationId, :deprecated, :security ].each do |attr_name|
        define_method(attr_name) do |value|
          metadata[:operation][attr_name] = value
        end
      end

      # NOTE: 'description' requires special treatment because ExampleGroup already
      # defines a method with that name. Provide an override that supports the existing
      # functionality while also setting the appropriate metadata if applicable
      def description(value=nil)
        return super() if value.nil?
        metadata[:operation][:description] = value 
      end

      # These are array properties - note the splat operator
      [ :tags, :consumes, :produces, :schemes ].each do |attr_name|
        define_method(attr_name) do |*value|
          metadata[:operation][attr_name] = value
        end
      end

      def parameter(attributes)
        attributes[:required] = true if attributes[:in].to_sym == :path
        metadata[:operation][:parameters] ||= []
        metadata[:operation][:parameters] << attributes
      end

      def response(code, description, &block)
        api_metadata = { response: { code: code, description: description } }
        context(description, api_metadata, &block)
      end

      def schema(value)
        metadata[:response][:schema] = value
      end

      def header(name, attributes)
        metadata[:response][:headers] ||= {}
        metadata[:response][:headers][name] = attributes
      end

      def run_test!
        # NOTE: rspec 2.x support
        if RSPEC_VERSION < 3
          before do
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response" do
            assert_response_matches_metadata(example.metadata)
          end
        else
          before do |example|
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response" do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end
    end
  end
end
