class Person < ApplicationRecord
  validates :title_prefix, :full_name, :position_short, :unit_code, presence: true
  validates :employee_code, uniqueness: true, allow_nil: true, format: { with: /\A\d+\z/, allow_nil: true }

  scope :alphabetical, -> { order(:full_name) }

  # "นายสมชาย ใจดี"
  def display_name = "#{title_prefix}#{full_name}"

  # "วศก.5 (ฉ) สชก.(บก-ท)" — the way people are referred to in memos.
  def position_with_unit = "#{position_short} #{unit_code}"
end
