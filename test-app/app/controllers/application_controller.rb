# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  wrap_parameters format: [:json]

  respond_to :json
  rescue_from 'ActionController::UnknownFormat' do |_ex|
    head :not_acceptable
  end
end
