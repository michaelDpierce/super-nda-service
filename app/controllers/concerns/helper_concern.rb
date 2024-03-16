# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

module HelperConcern
  extend ActiveSupport::Concern

  def basic_search_resource_by!
    return if params[:q].blank?

    q = params[:q].downcase
    @resource = @resource.main_search(q)
  end
end