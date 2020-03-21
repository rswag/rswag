module Rswag
  module Specs
    module ExampleGroupHelpers

      def path(template, metadata={}, &block)
        metadata[:path_item] = { template: template }
        describe(template, metadata, &block)
      end

      [ :get, :post, :patch, :put, :delete, :head, :options, :trace ].each do |verb|
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

      ## OA3
      # # MUST HAVES
      # # need to run ```npm install``` in rswag-ui dir to get assets to load
      # # not sure if its an asset issue or what but this should load => http://localhost:3000/api-docs/index.html
      # # TODO: fix examples in the main README

      # def request_body(attributes)
      #   # can make this generic, and accept any incoming hash (like parameter method)
      #   attributes.compact!

      #   if metadata[:operation][:requestBody].blank?
      #     metadata[:operation][:requestBody] = attributes
      #   elsif metadata[:operation][:requestBody] && metadata[:operation][:requestBody][:content]
      #     # merge in
      #     content_hash = metadata[:operation][:requestBody][:content]
      #     incoming_content_hash = attributes[:content]
      #     content_hash.merge!(incoming_content_hash) if incoming_content_hash
      #   end
      # end

      # def request_body_json(schema:, required: true, description: nil, examples: nil)
      #   passed_examples = Array(examples)
      #   content_hash = { 'application/json' => { schema: schema, examples: examples }.compact! || {} }
      #   request_body(description: description, required: required, content: content_hash)
      #   if passed_examples.any?
      #     # the request_factory is going to have to resolve the different ways that the example can be given
      #     # it can contain a 'value' key which is a direct hash (easiest)
      #     # it can contain a 'external_value' key which makes an external call to load the json
      #     # it can contain a '$ref' key. Which points to #/components/examples/blog
      #     passed_examples.each do |passed_example|
      #       if passed_example.is_a?(Symbol)
      #         example_key_name = passed_example
      #         # TODO: write more tests around this adding to the parameter
      #         # if symbol try and use save_request_example
      #         param_attributes = { name: example_key_name, in: :body, required: required, param_value: example_key_name, schema: schema }
      #         parameter(param_attributes)
      #       elsif passed_example.is_a?(Hash) && passed_example[:externalValue]
      #         param_attributes = { name: passed_example, in: :body, required: required, param_value: passed_example[:externalValue], schema: schema }
      #         parameter(param_attributes)
      #       elsif passed_example.is_a?(Hash) && passed_example['$ref']
      #         param_attributes = { name: passed_example, in: :body, required: required, param_value: passed_example['$ref'], schema: schema }
      #         parameter(param_attributes)
      #       end
      #     end
      #   end
      # end

      # def request_body_text_plain(required: false, description: nil, examples: nil)
      #   content_hash = { 'test/plain' => { schema: {type: :string}, examples: examples }.compact! || {} }
      #   request_body(description: description, required: required, content: content_hash)
      # end

      # # TODO: add examples to this like we can for json, might be large lift as many assumptions are made on content-type
      # def request_body_xml(schema:,required: false, description: nil, examples: nil)
      #   passed_examples = Array(examples)
      #   content_hash = { 'application/xml' => { schema: schema, examples: examples }.compact! || {} }
      #   request_body(description: description, required: required, content: content_hash)
      # end

      # def request_body_multipart(schema:, description: nil)
      #   content_hash = { 'multipart/form-data' => { schema: schema }}
      #   request_body(description: description, content: content_hash)

      #   schema.extend(Hashie::Extensions::DeepLocate)
      #   file_properties = schema.deep_locate ->(_k, v, _obj) { v == :binary }
      #   hash_locator = []

      #   file_properties.each do |match|
      #     hash_match = schema.deep_locate ->(_k, v, _obj) { v == match }
      #     hash_locator.concat(hash_match) unless hash_match.empty?
      #   end

      #   property_hashes = hash_locator.flat_map do |locator|
      #     locator.select { |_k,v| file_properties.include?(v) }
      #   end

      #   existing_keys = []
      #   property_hashes.each do |property_hash|
      #     property_hash.keys.each do |k|
      #       if existing_keys.include?(k)
      #         next
      #       else
      #         file_name = k
      #         existing_keys << k
      #         parameter name: file_name, in: :formData, type: :file, required: true
      #       end
      #     end
      #   end
      # end


      def parameter(attributes)
        if attributes[:in] && attributes[:in].to_sym == :path
          attributes[:required] = true
        end

        if metadata.has_key?(:operation)
          metadata[:operation][:parameters] ||= []
          metadata[:operation][:parameters] << attributes
        else
          metadata[:path_item][:parameters] ||= []
          metadata[:path_item][:parameters] << attributes
        end
      end

      def response(code, description, metadata={}, &block)
        metadata[:response] = { code: code, description: description }
        context(description, metadata, &block)
      end

      def schema(value)
        metadata[:response][:schema] = value
      end
      ## OA3
      # def schema(value, content_type: 'application/json')
      #   content_hash = {content_type => {schema: value}}
      #   metadata[:response][:content] = content_hash
      # end

      def header(name, attributes)
        metadata[:response][:headers] ||= {}

        ## OA3
        # if attributes[:type] && attributes[:schema].nil?
        #   attributes[:schema] = { type: attributes[:type] }
        #   attributes.delete(:type)
        # end

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
