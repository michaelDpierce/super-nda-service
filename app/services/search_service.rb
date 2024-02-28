# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
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

    if @query.blank?
      @resource_by_q =
        user.projects_with_access
          .limit(@limit)
    else
      @resource_by_q =
        user.projects_with_access
          .main_search(@query)
          .limit(@limit)
    end
  end

  def build_ungrouped_item_result(object)
    { 
      id: object.hashid,
      key: object.id,
      text: "#{object.name} - #{object.hashid}",
      type: object.class.name
    }
  end
end
