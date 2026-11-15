class Organization < ApplicationRecord
  include Auditable

  has_many :departments, dependent: :restrict_with_error
  has_many :positions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
