# frozen_string_literal: true

module Rswag
  module Specs
    class Configuration
      def initialize(rspec_config)
        @rspec_config = rspec_config
      end

      def swagger_root
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: The method will be renamed to "openapi_root" in v3.0')
        @swagger_root ||= begin
          if @rspec_config.swagger_root.nil?
            raise ConfigurationError, 'No swagger_root provided. See swagger_helper.rb'
          end

          @rspec_config.swagger_root
        end
      end

      def swagger_docs
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: The method will be renamed to "openapi_specs" in v3.0')
        @swagger_docs ||= begin
          if @rspec_config.swagger_docs.nil? || @rspec_config.swagger_docs.empty?
            raise ConfigurationError, 'No swagger_docs defined. See swagger_helper.rb'
          end

          @rspec_config.swagger_docs
        end
      end

      def swagger_dry_run
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: The method will be renamed to "rswag_dry_run" in v3.0')
        return @swagger_dry_run if defined? @swagger_dry_run
        if ENV.key?('SWAGGER_DRY_RUN')
          @rspec_config.swagger_dry_run = ENV['SWAGGER_DRY_RUN'] == '1'
        end
        @swagger_dry_run = @rspec_config.swagger_dry_run.nil? || @rspec_config.swagger_dry_run
      end

      def swagger_format
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: The method will be renamed to "openapi_format" in v3.0')
        @swagger_format ||= begin
          @rspec_config.swagger_format = :json if @rspec_config.swagger_format.nil? || @rspec_config.swagger_format.empty?
          raise ConfigurationError, "Unknown swagger_format '#{@rspec_config.swagger_format}'" unless [:json, :yaml].include?(@rspec_config.swagger_format)

          @rspec_config.swagger_format
        end
      end

      def get_swagger_doc(name)
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: The method will be renamed to "get_openapi_spec" in v3.0')
        return swagger_docs.values.first if name.nil?
        raise ConfigurationError, "Unknown swagger_doc '#{name}'" unless swagger_docs[name]

        swagger_docs[name]
      end

      def get_swagger_doc_version(name)
        doc = get_swagger_doc(name)
        doc[:openapi] || doc[:swagger]
      end

      def swagger_strict_schema_validation
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: The method will be renamed to "openapi_strict_schema_validation" in v3.0')
        @swagger_strict_schema_validation ||= (@rspec_config.swagger_strict_schema_validation || false)
      end
    end

    class ConfigurationError < StandardError; end
  end
end
