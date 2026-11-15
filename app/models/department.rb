# ส่วนงาน. Users see the cases of their own department (Requirement NFR-05).
class Department < ApplicationRecord
  include Auditable

  belongs_to :organization
  belongs_to :parent, class_name: "Department", optional: true
  has_many :children, class_name: "Department", foreign_key: :parent_id, dependent: :restrict_with_error,
                      inverse_of: :parent
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :organization_id }
  validate :parent_in_same_organization

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:code) }

  def label = "#{code} · #{name}"

  private

  def parent_in_same_organization
    return if parent.nil?

    errors.add(:parent, "ต้องอยู่ในหน่วยงานเดียวกัน") if parent.organization_id != organization_id
    errors.add(:parent, "ซ้อนตัวเองไม่ได้") if parent_id.present? && parent_id == id
  end
end
