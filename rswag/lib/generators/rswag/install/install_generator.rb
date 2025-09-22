require 'rails/generators'

module Rswag
  class InstallGenerator < Rails::Generators::Base

    def install_components
      generate 'rswag:specs:install'
      generate 'rswag:api:install'
      generate 'rswag:ui:install'
    end
  end
end
