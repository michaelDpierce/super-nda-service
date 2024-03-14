# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::SharingController < V1::BaseController
  skip_before_action :authenticate_request!

  before_action :verify_group, only: %i[verify_code]

  # POST /v1/verify_code params: { id: 1, code: "123456" }
  def verify_code
    render json: SharingSerializer.new(@group)
  end

  private

  def verify_group
    unless params[:id].present? && params[:code].present?
      render json: { error: "Unauthorized Access." }, status: :unauthorized
    end

    numeric_id = Group.decode_id(params[:id])
    @group = Group.find_by(id: numeric_id, code: params[:code])

    unless @group.present? && @group.code == params[:code]
      render json: { error: "Unauthorized Access." }, status: :unauthorized
    end
  end
end
