# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class MeetingAttendance < ApplicationRecord
  belongs_to :contact
  belongs_to :directory_file

  enum status: { absent: 0, remote: 1, in_person: 2, present: 3 }
end
