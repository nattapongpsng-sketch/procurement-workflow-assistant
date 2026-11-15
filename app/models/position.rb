# ตำแหน่ง. Approval authority per position comes in M2 (Requirement FR-02).
class Position < ApplicationRecord
  belongs_to :organization
  has_many :users, dependent: :restrict_with_error

  validates :title, presence: true, uniqueness: { scope: :organization_id }

  scope :ordered, -> { order(:title) }

  def label = short_title.present? ? "#{title} (#{short_title})" : title
end
