# ประเภทเงินได้สำหรับภาษีหัก ณ ที่จ่าย: rate applies to the amount before VAT when the
# payment reaches minimum_amount.
class WithholdingTaxType < ApplicationRecord
  include Auditable

  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :name, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validates :minimum_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  def label = "#{name} (#{(rate * 100).to_s('F').sub(/\.0\z/, '')}%)"
end
