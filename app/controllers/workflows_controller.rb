class WorkflowsController < ApplicationController
  SUGGESTIONS = [ "ซื้อ AI", "license ซอฟต์แวร์", "Claude" ].freeze

  def index
    @query = params[:q].to_s.strip
    @results = WorkflowSearch.call(@query)
  end

  def show
    code, version = params[:id].to_s.match(/\A([a-z0-9_]+)-v(\d+)\z/)&.captures
    raise ActiveRecord::RecordNotFound unless code

    @workflow = WorkflowTemplate.published.includes(:workflow_steps, :document_templates).find_by!(code:, version:)
  end
end
