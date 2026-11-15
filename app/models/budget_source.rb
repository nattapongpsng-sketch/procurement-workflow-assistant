# A budget allocation letter (e.g. กนว.(พน.)1182/2569) that purchases are charged to.
class BudgetSource < ApplicationRecord
  include Auditable

  validates :ref_doc_no, presence: true, uniqueness: true
  validates :ref_doc_date, :owner_unit, :budget_type, :fiscal_year, :account_name, :account_code,
            :cost_center, presence: true
  validates :limit_amount, numericality: { greater_than: 0 }, allow_nil: true

  def label = "#{ref_doc_no} · #{budget_type}ปี #{fiscal_year} ของ #{owner_unit}"
end
