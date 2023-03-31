# frozen_string_literal: true

require 'active_support'

module Rswag
  module Specs
    module ExampleGroupHelpers
      ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: Support for Ruby 2.6 will be dropped in v3.0') if RUBY_VERSION.start_with? '2.6'

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


      def request_body_example(value:, summary: nil, name: nil) 
        if metadata.key?(:operation) 
          metadata[:operation][:request_examples] ||= []
          example = { value: value } 
          example[:summary] = summary if summary 
          # We need the examples to have a unique name for a set of examples, so just make the name the length if one isn't provided.
          example[:name] = name || metadata[:operation][:request_examples].length()
          metadata[:operation][:request_examples] << example
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
      def examples(examples = nil)
        return super() if examples.nil?
        # should we add a deprecation warning?
        examples.each_with_index do |(mime, example_object), index|
          example(mime, "example_#{index}", example_object)
        end
      end

      def example(mime, name, value, summary=nil, description=nil)
        # Todo - move initialization of metadata somewhere else.
        if metadata[:response][:content].blank?
          metadata[:response][:content] = {}
        end

        if metadata[:response][:content][mime].blank?
          metadata[:response][:content][mime] = {}
          metadata[:response][:content][mime][:examples] = {}
        end

        example_object = {
          value: value,
          summary: summary,
          description: description
        }.select { |_, v| v.present? }
        # TODO, issue a warning if example is being overridden with the same key
        metadata[:response][:content][mime][:examples].merge!(
          { name.to_sym => example_object }
        )
      end

      #
      # Perform request and assert response matches swagger definitions
      #
      # @param swagger_strict_schema_validation: nil [Boolean] whether to validate response against given schema strictly
      # @param &block [Proc] you can make additional assertions within that block
      # @return [void]
      def run_test!(**options, &block)
        options[:rswag] = true unless options.key?(:rswag)

        if RSPEC_VERSION < 3
          ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: Support for RSpec 2.X will be dropped in v3.0')
          before do
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response", **options do
            assert_response_matches_metadata(metadata)
            block.call(response) if block_given?
          end
        else
          before do |example|
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response", **options do |example|
            assert_response_matches_metadata(example.metadata, &block)
            example.instance_exec(response, &block) if block_given?
          end
        end
      end
    end
  end
end
