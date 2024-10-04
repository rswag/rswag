# frozen_string_literal: true

require 'rspec/core'
require 'rswag/specs/example_group_helpers'
require 'rswag/specs/example_helpers'
require 'rswag/specs/configuration'
require 'rswag/specs/railtie' if defined?(Rails::Railtie)

module Rswag
  module Specs
    RENAMED_METHODS = {
      swagger_root: :openapi_root,
      swagger_docs: :openapi_specs,
      swagger_dry_run: :rswag_dry_run,
      swagger_format: :openapi_format
    }.freeze
    private_constant :RENAMED_METHODS

    # Extend RSpec with a swagger-based DSL
    ::RSpec.configure do |c|
      c.add_setting :openapi_root
      c.add_setting :openapi_specs
      c.add_setting :rswag_dry_run
      c.add_setting :openapi_format, default: :json
      c.add_setting :openapi_strict_schema_validation
      c.add_setting :openapi_all_properties_required
      c.add_setting :openapi_no_additional_properties
      c.extend ExampleGroupHelpers, type: :request
      c.include ExampleHelpers, type: :request
    end

    def self.config
      @config ||= Configuration.new(RSpec.configuration)
    end

    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new('3.0', 'rswag-specs')
    end

    # Support Rails 3+ and RSpec 2+ (sigh!)
    RAILS_VERSION = Rails::VERSION::MAJOR
    RSPEC_VERSION = RSpec::Core::Version::STRING.split('.').first.to_i

    RSpec::Core::Configuration.class_eval do
      RENAMED_METHODS.each do |old_name, new_name|
        define_method("#{old_name}=") do |*args, &block|
          public_send("#{new_name}=", *args, &block)
        end
      end

      define_method('swagger_strict_schema_validation=') do |*args, &block|
        public_send('openapi_strict_schema_validation=', *args, &block)
      end
    end

    Specs.deprecator.deprecate_methods(
      RSpec::Core::Configuration,
      RENAMED_METHODS.to_h { |old_name, new_name| ["#{old_name}=".to_sym, "#{new_name}=".to_sym] }
    )

    Specs.deprecator.deprecate_methods(
      RSpec::Core::Configuration,
      :openapi_strict_schema_validation= => 'use openapi_all_properties_required and openapi_no_additional_properties set to true'
    )

    if RUBY_VERSION.start_with? '2.6'
      Specs.deprecator.warn('Rswag::Specs: WARNING: Support for Ruby 2.6 will be dropped in v3.0')
    end

    Specs.deprecator.warn('Rswag::Specs: WARNING: Support for RSpec 2.X will be dropped in v3.0') if RSPEC_VERSION < 3
  end
end
