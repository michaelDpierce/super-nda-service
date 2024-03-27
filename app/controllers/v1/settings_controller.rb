# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::SettingsController < V1::BaseController
  before_action :set_user, only: %i[show update]

  # GET /v1/settings
  def show
    if @user.signature.attached?
      signature =
        Rails.application.routes.url_helpers.rails_blob_url(@user.signature)
    else
      signature = nil
    end

    render json: {
      first_name: @user.first_name,
      last_name: @user.last_name,
      email: @user.email,
      signature: signature
    }
  end

  # PUT /v1/settings
  def update
    if params[:user][:signature].present?
      signature_file =
        base64_to_file(params[:user][:signature], "signature.png")
      
      @user.signature.attach(
        io: signature_file,
        filename: "signature.png",
        content_type: "image/png"
      )
    end

    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = @current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name)
  end

  def base64_to_file(base64_string, filename)
    decoded_data = Base64.decode64(base64_string.split(',').last)
    
    StringIO.new(decoded_data).tap do |file|
      file.class.class_eval { attr_accessor :original_filename, :content_type }
      file.original_filename = filename
      file.content_type = "image/png"
    end
  end
end