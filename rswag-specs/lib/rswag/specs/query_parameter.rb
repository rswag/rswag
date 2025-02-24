# frozen_string_literal: true

require 'debug'

module Rswag
  module Specs
    class QueryParameter
      STYLE_SEPARATORS = {
        form: ',',
        spaceDelimited: '%20',
        pipeDelimited: '|'
      }.freeze

      def initialize(definition, value)
        raise ArgumentError, "'type' is not supported field for Parameter" if definition[:type].present?

        @definition = definition
        @value = value
      end

      def schema = @definition[:schema]
      def style = @definition[:style].try(:to_sym) || :form
      def explode = @definition[:explode].nil? ? true : @definition[:explode]
      def type = @definition[:schema][:type]&.to_sym
      def escaped_value = CGI.escape(@value.to_s)
      def escaped_name = CGI.escape(@definition[:name].to_s)
      def escaped_array = @value.to_a.flatten.map { |v| CGI.escape(v.to_s) }

      def formatting_attributes
        { schema: schema,
          style: style,
          explode: explode,
          type: type,
          value: @value }
      end

      def to_query
        case formatting_attributes
        in { schema: nil } | { value: nil } then nil
        in { type: :object, style: :deepObject } then { @definition[:name] => @value }.to_query
        in { type: :object, style: :form, explode: true } then @value.to_query
        in { type: :array, explode: true } then escaped_array.map { |v| "#{escaped_name}=#{v}" }.join('&')
        in { type: :object, style: :form } | { type: :array }
          "#{escaped_name}=#{escaped_array.join(STYLE_SEPARATORS[style])}"
        else "#{escaped_name}=#{escaped_value}"
        end
      end
    end
  end
end
