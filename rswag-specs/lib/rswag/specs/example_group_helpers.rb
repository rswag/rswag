# frozen_string_literal: true
require 'hashie'

module Rswag
  module Specs
    module ExampleGroupHelpers
      def path(template, metadata = {}, &block)
        metadata[:path_item] = { template: template }
        describe(template, metadata, &block)
      end

      %i[get post patch put delete head].each do |verb|
        define_method(verb) do |summary, &block|
          api_metadata = { operation: { verb: verb, summary: summary } }
          describe(verb, api_metadata, &block)
        end
      end

      %i[operationId deprecated security].each do |attr_name|
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
      %i[tags consumes produces schemes].each do |attr_name|
        define_method(attr_name) do |*value|
          metadata[:operation][attr_name] = value
        end
      end

      # NICE TO HAVE
      # TODO: update generator templates to include 3.0 syntax
      # TODO: setup travis CI?

      # MUST HAVES
      # TODO: look at integrating and documenting the rest of the responses in the blog_spec and get a clean 3.0 output
      # Then can look at handling different request_body things like $ref, etc
      # TODO: look at adding request_body method to handle diffs in Open API 2.0 to 3.0
      # TODO: look at adding examples  in content request_body
      # https://swagger.io/docs/specification/describing-request-body/
      # need to make sure we output requestBody in the swagger generator .json
      # also need to make sure that it can handle content: , required: true/false, schema: ref

      def request_body(attributes)
        # can make this generic, and accept any incoming hash (like parameter method)
        attributes.compact!
        metadata[:operation][:requestBody] = attributes
      end

      def request_body_json(schema:, required: true, description: nil, examples: nil)
        passed_examples = Array(examples)
        content_hash = { 'application/json' => { schema: schema, examples: examples }.compact! || {} }
        request_body(description: description, required: required, content: content_hash)
        if passed_examples.any?
          # the request_factory is going to have to resolve the different ways that the example can be given
          # it can contain a 'value' key which is a direct hash (easiest)
          # it can contain a 'external_value' key which makes an external call to load the json
          # it can contain a '$ref' key. Which points to #/components/examples/blog
          if passed_examples.first.is_a?(Symbol)
            example_key_name = passed_examples.first # can come up with better scheme here
            # TODO: write more tests around this adding to the parameter
            # if symbol try and use save_request_example
            param_attributes = { name: example_key_name, in: :body, required: required, param_value: example_key_name, schema: schema }
            parameter(param_attributes)
          end
        end
      end

      def request_body_multipart(schema:, description: nil)
        content_hash = { 'multipart/form-data' => { schema: schema }}
        request_body(description: description, content: content_hash)

        schema.extend(Hashie::Extensions::DeepLocate)
        file_properties = schema.deep_locate -> (_k, v, _obj) { v == :binary } 

        hash_locator = []

        file_properties.each do |match|
          hash_match = schema.deep_locate -> (_k, v, _obj) { v == match }
          hash_locator.concat(hash_match) unless hash_match.empty?
        end

        property_hashes = hash_locator.flat_map do |locator|
          locator.select { |_k,v| file_properties.include?(v) }
        end

        property_hashes.each do |property_hash|
          file_name = property_hash.keys.first
          parameter name: file_name, in: :formData, type: :file, required: true
        end
      end

      def parameter(attributes)
        if attributes[:in] && attributes[:in].to_sym == :path
          attributes[:required] = true
        end

        if attributes[:type] && attributes[:schema].nil?
          attributes[:schema] = {type: attributes[:type]}
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

      def schema(value, content_type: 'application/json')
        content_hash = {content_type => {schema: value}}
        metadata[:response][:content] = content_hash
      end

      def header(name, attributes)
        metadata[:response][:headers] ||= {}
         
        if attributes[:type] && attributes[:schema].nil?
          attributes[:schema] = {type: attributes[:type]}
          attributes.delete(:type)
        end

        metadata[:response][:headers][name] = attributes
      end

      # NOTE: Similar to 'description', 'examples' need to handle the case when
      # being invoked with no params to avoid overriding 'examples' method of
      # rspec-core ExampleGroup
      def examples(example = nil)
        return super() if example.nil?

        metadata[:response][:examples] = example
      end

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
            submit_request(example.metadata)                                                                                            #
          end

          it "returns a #{metadata[:response][:code]} response" do |example|
            assert_response_matches_metadata(example.metadata, &block)
            example.instance_exec(response, &block) if block_given?
          end

          after do |example|
            body_parameter = example.metadata[:operation]&.dig(:parameters)&.detect { |p| p[:in] == :body && p[:required] }

            if body_parameter && respond_to?(body_parameter[:name]) && example.metadata[:operation][:requestBody][:content]['application/json']
              # save response examples by default
              example.metadata[:response][:examples] = { 'application/json' => JSON.parse(response.body, symbolize_names: true) } unless response.body.to_s.empty?
               
              # save request examples using the let(:param_name) { REQUEST_BODY_HASH } syntax in the test
              if response.code.to_s =~ /^2\d{2}$/
                example.metadata[:operation][:requestBody][:content]['application/json'] = { examples: {} } unless example.metadata[:operation][:requestBody][:content]['application/json'][:examples]
                json_request_examples = example.metadata[:operation][:requestBody][:content]['application/json'][:examples]
                json_request_examples[body_parameter[:name]] = { value: send(body_parameter[:name]) }
                example.metadata[:operation][:requestBody][:content]['application/json'][:examples] = json_request_examples
              end
            end
          end
        end
      end
    end
  end
end
