# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::ContactsController < V1::BaseController
  before_action :find_contact, only: %i[show update]

  # GET /v1/contacts/:hashid
  def show
    render json: ContactSerializer.new(@contact, {}).serialized_json
  end

  # PUT /v1/contacts/:hashid
  # PATCH /v1/contacts/:hashid
  def update
    if @contact.update(update_contact_params)
      render json: ContactSerializer.new(@contact, {}).serialized_json
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_contact
    @contact = Contact.find(params[:id])
  end

  def update_contact_params
    params
      .require(:contact)
      .permit(:prefix, :first_name, :last_name)
  end
end
