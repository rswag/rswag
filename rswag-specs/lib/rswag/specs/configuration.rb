# frozen_string_literal: true

module Rswag
  module Specs
    class Configuration
      def initialize(rspec_config)
        @rspec_config = rspec_config
      end

      def openapi_root
        @openapi_root ||= begin
          if @rspec_config.openapi_root.nil?
            raise ConfigurationError, 'No openapi_root provided. See openapi_helper.rb'
          end

          @rspec_config.openapi_root
        end
      end

      def openapi_specs
        @openapi_specs ||= begin
          if @rspec_config.openapi_specs.nil? || @rspec_config.openapi_specs.empty?
            raise ConfigurationError, 'No openapi_specs defined. See openapi_helper.rb'
          end

          @rspec_config.openapi_specs
        end
      end

      def rswag_dry_run
        return @rswag_dry_run if defined? @rswag_dry_run
        if ENV.key?('RSWAG_DRY_RUN')
          @rspec_config.rswag_dry_run = ENV['RSWAG_DRY_RUN'] == '1'
        end
        @rswag_dry_run = @rspec_config.rswag_dry_run.nil? || @rspec_config.rswag_dry_run
      end

      def openapi_format
        @openapi_format ||= begin
          if @rspec_config.openapi_format.nil? || @rspec_config.openapi_format.empty?
            @rspec_config.openapi_format = :json
          end
          unless [:json, :yaml].include?(@rspec_config.openapi_format)
            raise ConfigurationError, "Unknown openapi_format '#{@rspec_config.openapi_format}'"
          end

          @rspec_config.openapi_format
        end
      end

      def get_openapi_spec(name)
        return openapi_specs.values.first if name.nil?
        raise ConfigurationError, "Unknown openapi_spec '#{name}'" unless openapi_specs[name]

        openapi_specs[name]
      end

      def openapi_strict_schema_validation
        @openapi_strict_schema_validation ||= (@rspec_config.openapi_strict_schema_validation || false)
      end
    end

    class ConfigurationError < StandardError; end
  end
end
