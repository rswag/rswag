# frozen_string_literal: true

module Rswag
  module Specs
    class Configuration
      def initialize(rspec_config)
        @rspec_config = rspec_config
      end

      def swagger_root
        @swagger_root ||= begin
          if @rspec_config.swagger_root.nil?
            raise ConfigurationError, 'No swagger_root provided. See swagger_helper.rb'
          end

          @rspec_config.swagger_root
        end
      end

      def swagger_docs
        @swagger_docs ||= begin
          if @rspec_config.swagger_docs.nil? || @rspec_config.swagger_docs.empty?
            raise ConfigurationError, 'No swagger_docs defined. See swagger_helper.rb'
          end

          @rspec_config.swagger_docs
        end
      end

      def swagger_dry_run
        @swagger_dry_run ||= begin
          @rspec_config.swagger_dry_run.nil? || @rspec_config.swagger_dry_run
        end
      end

      def get_swagger_doc(name)
        return swagger_docs.values.first if name.nil?
        raise ConfigurationError, "Unknown swagger_doc '#{name}'" unless swagger_docs[name]

        swagger_docs[name]
      end
    end

    class ConfigurationError < StandardError; end
  end
end
