# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::SettingsController < V1::BaseController
  before_action :set_user, only: %i[show update]

  # GET /v1/settings
  def show
    render json: {
      first_name: @user.first_name,
      last_name: @user.last_name,
      company: @user.company,
      email: @user.email
    }
  end

  # PUT /v1/settings
  def update
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
    params.require(:user).permit(:first_name, :last_name, :company)
  end
end