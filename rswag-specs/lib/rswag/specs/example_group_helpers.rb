# frozen_string_literal: true

module Rswag
  module Specs
    module ExampleGroupHelpers
      def path(template, metadata = {}, &block)
        metadata[:path_item] = { template: template }
        describe(template, metadata, &block)
      end

      [:get, :post, :patch, :put, :delete, :head, :options, :trace].each do |verb|
        define_method(verb) do |summary, &block|
          api_metadata = { operation: { verb: verb, summary: summary } }
          describe(verb, api_metadata, &block)
        end
      end

      [:operationId, :deprecated, :security].each do |attr_name|
        define_method(attr_name) do |value|
          metadata[:operation][attr_name] = value
        end
      end

      # NOTE: 'description' requires special treatment because ExampleGroup already
      # defines a method with that name. Provide an override that supports the existing
      # functionality while also setting the appropriate metadata if applicable
      def description(value = nil)
        return super() if value.nil?

        metadata[:operation][:description] = value
      end

      # These are array properties - note the splat operator
      [:tags, :consumes, :produces, :schemes].each do |attr_name|
        define_method(attr_name) do |*value|
          metadata[:operation][attr_name] = value
        end
      end

      def parameter(attributes)
        if attributes[:in] && attributes[:in].to_sym == :path
          attributes[:required] = true
        end

        if metadata.key?(:operation)
          metadata[:operation][:parameters] ||= []
          metadata[:operation][:parameters] << attributes
        else
          metadata[:path_item][:parameters] ||= []
          metadata[:path_item][:parameters] << attributes
        end
      end

      def response(code, description, metadata = {}, &block)
        metadata[:response] = { code: code, description: description }
        context(description, metadata, &block)
      end

      def schema(value)
        metadata[:response][:schema] = value
      end

      def header(name, attributes)
        metadata[:response][:headers] ||= {}

        metadata[:response][:headers][name] = attributes
      end

      # NOTE: Similar to 'description', 'examples' need to handle the case when
      # being invoked with no params to avoid overriding 'examples' method of
      # rspec-core ExampleGroup
      def examples(example = nil)
        return super() if example.nil?

        metadata[:response][:examples] = example
      end

      ## OA3
      # # checks the examples in the parameters should be able to add $ref and externalValue examples.
      # # This syntax would look something like this in the integration _spec.rb file
      # #
      # # request_body_json schema: { '$ref' => '#/components/schemas/blog' },
      # #   examples: [:blog, {name: :external_blog,
      # #                       externalValue: 'http://api.sample.org/myjson_example'},
      # #                     {name: :another_example,
      # #                       '$ref' => '#/components/examples/flexible_blog_example'}]
      # # The first value :blog, points to a let param of the same name, and is used to make the request in the
      # # integration test (it is used to build the request payload)
      # #
      # # The second item in the array shows how to add an externalValue for the examples in the requestBody section
      # # The third item shows how to add a $ref item that points to the components/examples section of the swagger spec.
      # #
      # # NOTE: that the externalValue will produce valid example syntax in the swagger output, but swagger-ui
      # # will not show it yet
      # def merge_other_examples!(example_metadata)
      #   # example.metadata[:operation][:requestBody][:content]['application/json'][:examples]
      #   content_node = example_metadata[:operation][:requestBody][:content]['application/json']
      #   return unless content_node

      #   external_example = example_metadata[:operation]&.dig(:parameters)&.detect { |p| p[:in] == :body && p[:name].is_a?(Hash) && p[:name][:externalValue] } || {}
      #   ref_example = example_metadata[:operation]&.dig(:parameters)&.detect { |p| p[:in] == :body && p[:name].is_a?(Hash) && p[:name]['$ref'] } || {}
      #   examples_node = content_node[:examples] ||= {}

      #   nodes_to_add = []
      #   nodes_to_add << external_example unless external_example.empty?
      #   nodes_to_add << ref_example unless ref_example.empty?

      #   nodes_to_add.each do |node|
      #     json_request_examples = examples_node ||= {}
      #     other_name = node[:name][:name]
      #     other_key = node[:name][:externalValue] ? :externalValue : '$ref'
      #     if other_name
      #       json_request_examples.merge!(other_name => {other_key => node[:param_value]})
      #     end
      #   end
      # end

      def run_test!(&block)
        # NOTE: rspec 2.x support
        if RSPEC_VERSION < 3
          before do
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response" do
            assert_response_matches_metadata(metadata)
            block.call(response) if block_given?
          end
        else
          before do |example|
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response" do |example|
            assert_response_matches_metadata(example.metadata, &block)
            example.instance_exec(response, &block) if block_given?
          end

          ## OA3
          # after do |example|
          #   body_parameter = example.metadata[:operation]&.dig(:parameters)&.detect { |p| p[:in] == :body && p[:required] }

          #   if body_parameter && respond_to?(body_parameter[:name]) && example.metadata[:operation][:requestBody][:content]['application/json']
          #     # save response examples by default
          #     if example.metadata[:response][:examples].nil? || example.metadata[:response][:examples].empty?
          #       example.metadata[:response][:examples] = { 'application/json' => JSON.parse(response.body, symbolize_names: true) } unless response.body.to_s.empty?
          #     end

          #     # save request examples using the let(:param_name) { REQUEST_BODY_HASH } syntax in the test
          #     if response.code.to_s =~ /^2\d{2}$/
          #       example.metadata[:operation][:requestBody][:content]['application/json'] = { examples: {} } unless example.metadata[:operation][:requestBody][:content]['application/json'][:examples]
          #       json_request_examples = example.metadata[:operation][:requestBody][:content]['application/json'][:examples]
          #       json_request_examples[body_parameter[:name]] = { value: send(body_parameter[:name]) }

          #       example.metadata[:operation][:requestBody][:content]['application/json'][:examples] = json_request_examples
          #     end
          #   end

          #   self.class.merge_other_examples!(example.metadata) if example.metadata[:operation][:requestBody]

          # end
        end
      end
    end
  end
end
