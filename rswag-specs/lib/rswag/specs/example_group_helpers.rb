# frozen_string_literal: true

require 'active_support'

module Rswag
  module Specs
    module ExampleGroupHelpers
      def path(template, *tags, **metadata, &block)
        metadata[:path_item] = { template: template }
        describe(template, *tags, **metadata, &block)
      end

      %i[get post patch put delete head options trace].each do |verb|
        define_method(verb) do |summary, *tags, **metadata, &block|
          api_metadata = { operation: { verb: verb, summary: summary } }.deep_merge(metadata)
          describe(verb, *tags, **api_metadata, &block)
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

      def parameter(attributes)
        attributes[:required] = true if attributes[:in] && attributes[:in].to_sym == :path

        if metadata.key?(:operation)
          metadata[:operation][:parameters] ||= []
          metadata[:operation][:parameters] << attributes
        else
          metadata[:path_item][:parameters] ||= []
          metadata[:path_item][:parameters] << attributes
        end
      end

      def request_body_example(value:, summary: nil, name: nil)
        return unless metadata.key?(:operation)

        metadata[:operation][:request_examples] ||= []
        example = { value: value }
        example[:summary] = summary if summary
        # We need the examples to have a unique name for a set of examples,
        # so just make the name the length if one isn't provided.
        example[:name] = name || metadata[:operation][:request_examples].length
        metadata[:operation][:request_examples] << example
      end

      def response(code, description, *tags, **metadata, &block)
        metadata[:response] = { code: code, description: description }
        context(description, *tags, **metadata, &block)
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

      def example(mime, name, value, summary = nil, description = nil)
        # Todo - move initialization of metadata somewhere else.
        metadata[:response][:content] = {} if metadata[:response][:content].blank?

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
      # @param description [String] description of the test
      # @param args [Array] arguments to pass to the `it` method
      # @param options [Hash] options to pass to the `it` method
      # @param &block [Proc] you can make additional assertions within that block
      # @return [void]
      def run_test!(description = nil, *args, **options, &block)
        # rswag metadata value defaults to true
        options[:rswag] = true unless options.key?(:rswag)

        description ||= "returns a #{metadata[:response][:code]} response"

        before do |example|
          submit_request(example.metadata)
        end

        it description, *args, **options do |example|
          assert_response_matches_metadata(example.metadata, &block)
          example.instance_exec(response, &block) if block_given?
        end
      end
    end
  end
end
