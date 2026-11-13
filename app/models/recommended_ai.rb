# AI products PEA allows units to procure (Recommended List approved by ผวก.).
class RecommendedAi < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :list_version }
  validates :category, :vendor, :list_version, presence: true

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }

  def self.allowed?(name)
    active.exists?(name:)
  end
end
