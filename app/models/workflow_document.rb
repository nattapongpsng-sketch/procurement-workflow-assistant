class WorkflowDocument < ApplicationRecord
  belongs_to :workflow_template
  belongs_to :document_template

  validates :document_template_id, uniqueness: { scope: :workflow_template_id }
end
