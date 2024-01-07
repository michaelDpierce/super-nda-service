# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

module TimezoneHandler
  extend ActiveSupport::Concern

  included do
    around_action :set_timezone
  end

  private

  def set_timezone
    timezone = load_timezone
    timezone = 'Eastern Time (US & Canada)' if timezone.blank?

    if @current_user && @current_user.timezone != timezone
      @current_user.timezone = timezone
      @current_user.save(validate: false)
    end

    Time.use_zone(timezone) { yield }
  rescue ArgumentError => e
    yield
  end

  def load_timezone
    timezone_name = request.headers['Timezone']&.split(' ')&.last
    return timezone_name if timezone_name.present?

    timezone_offset = request.headers['TimezoneOffset']&.split(' ')&.last
    return if timezone_offset.blank?

    ActiveSupport::TimeZone[-timezone_offset.to_i.minutes]&.name
  end
end