require 'active_support/deprecation'
require 'rswag/api/configuration'
require 'rswag/api/engine' if defined?(Rails::Engine)

module Rswag
  module Api
    RENAMED_METHODS = {
      swagger_root: :openapi_root
    }.freeze
    private_constant :RENAMED_METHODS

    def self.configure
      yield(config)
    end

    def self.config
      @config ||= Configuration.new
    end

    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new('3.0', 'rswag-api')
    end

    Configuration.class_eval do
      RENAMED_METHODS.each do |old_name, new_name|
        define_method("#{old_name}=") do |*args, &block|
          public_send("#{new_name}=", *args, &block)
        end
      end
    end

    Api.deprecator.deprecate_methods(
      Configuration,
      RENAMED_METHODS.to_h { |old_name, new_name| ["#{old_name}=".to_sym, "#{new_name}=".to_sym] }
    )
  end
end
