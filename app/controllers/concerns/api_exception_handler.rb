# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

module ApiExceptionHandler
  extend ActiveSupport::Concern
  include ActionController::Rescue

  ExpiredSignature = Class.new(StandardError)
  DecodeError      = Class.new(StandardError)

  included do
    # rescue_from Pundit::NotAuthorizedError do |exception|
    #   render(json: { message: exception.message }, status: :forbidden)
    # end

    rescue_from ApiExceptionHandler::ExpiredSignature do |exception|
      render(json: { message: exception.message }, status: :invalid_token)
    end

    rescue_from ApiExceptionHandler::DecodeError do |exception|
      render(json: { message: exception.message }, status: :unauthorized)
    end

    rescue_from ActiveRecord::RecordInvalid do |exception|
      render(json: { message: exception.message }, status: :bad_request)
    end

    rescue_from ActiveRecord::RecordNotFound do |exception|
      render(json: { message: exception.message }, status: :not_found)
    end
  end
end
