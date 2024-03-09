# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

class SearchService
  attr_reader :status

  def initialize(user_id, query, limit = 10)
    @user_id    = user_id
    @limit      = limit
    @query      = query[:q]

    @status = 200
  end

  def result
    return @result if @result

    resource = resource_by_q

    @result = resource.map do |record|
      build_ungrouped_item_result(record)
    end

    @result
  end

  private

  def resource_by_q
    user = User.find(@user_id)

    sorted_projects = user.projects_with_access
      .order('status ASC, name ASC')
      .limit(@limit)

    if @query.blank?
      @resource_by_q = sorted_projects
    else
      @resource_by_q = sorted_projects.main_search(@query)
    end
  end

  def build_ungrouped_item_result(object)
    archived_text = object.status === "active" ? "" : " (Archived)"

    { 
      id: object.hashid,
      key: object.id,
      text: "#{object.name}#{archived_text} - ID: #{object.hashid}",
      type: object.class.name
    }
  end
end
