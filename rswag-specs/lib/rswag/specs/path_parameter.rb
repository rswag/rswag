# frozen_string_literal: true

require 'debug'

module Rswag
  module Specs
    class PathParameter
      def initialize(definition, value)
        unless value.present?
          raise ArgumentError, "`#{definition[:name]}`" \
            'parameter key present, but not defined within example group (i. e `it` or `let` block)'
        end

        @definition = definition
        @value = value
      end

      def sub_pattern = "{#{@definition[:name]}}"
      def sub_value = @value.to_s
      def sub_into_template!(template) = template.gsub!(sub_pattern, sub_value)
    end
  end
end
