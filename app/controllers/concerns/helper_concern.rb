# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

module HelperConcern
  extend ActiveSupport::Concern
  include Pagy::Backend

  # add include PgSearch::Model to model where you want to use this method
  def basic_search_resource_by!
    return if params[:q].blank?

    q = params[:q].downcase
    @resource = @resource.main_search(q)
  end

  def paginate(obj, options = {}, default_per_page = 25)
    page_size = (params[:per_page] || default_per_page).to_i
    pagy, records = pagy(obj, items: page_size)

    pagination = { total: pagy.count, current: pagy.page, pageSize: page_size }
    options[:meta] = (options[:meta] || {}).merge(pagination: pagination)

    records
  end

  def sort_by(obj)
    return obj if params[:sort_by].blank?

    arguments = params[:sort_by].split('|')

    order_statement = arguments.map do |argument|
      key, val = argument.split('=')
      val = val.include?('descend') ? 'DESC' : 'ASC'
      "#{key} #{val}"
    end

    obj.reorder(order_statement.join(', '))
  end

  def render_resource(resource, serializer, options = {})
    resource = paginate(sort_by(resource), options)
    render(json: serializer.new(resource, options).serialized_json)
  end

  def filter_resource_by_created!
    return if params[:created_at].blank?

    attr =
      if params[:created_at].kind_of?(Array) && params[:created_at].count > 1
        (params[:created_at][0]..params[:created_at][1])
      else
        params[:created_at]
      end

    @resource = @resource.where(created_at: attr)
  end
end