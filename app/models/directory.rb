# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class Directory < ApplicationRecord
  include Hashid::Rails

  has_ancestry(cache_depth: true)

  before_save :set_slug, :set_name

  belongs_to :project
  belongs_to :user

  has_many :directory_files, dependent: :destroy_async

  validates :name, :slug, presence: true

  scope :root, -> { roots.where(slug: ROOT_SLUG).first }
  scope :exclude_root, -> { roots.where.not(slug: ROOT_SLUG).first }

  def set_slug
    self.slug = root? ? ROOT_SLUG : name.gsub(REGEX_PATTERN, "").downcase
  end

  def set_name
    self.name = self.name.gsub(REGEX_PATTERN, "")
  end
end
