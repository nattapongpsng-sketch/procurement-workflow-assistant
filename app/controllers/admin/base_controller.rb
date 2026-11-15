# Settings pages (Requirement FR-01). Single organization for now; the data model
# already supports several.
class Admin::BaseController < ApplicationController
  require_role :admin

  private

  def current_organization = @current_organization ||= Organization.order(:id).first!
  helper_method :current_organization
end
