# A person who signs in. One user may hold several roles (Requirement "ผู้ใช้และบทบาท");
# separation of duties per case is enforced where the duties happen (M2/M3).
class User < ApplicationRecord
  include Auditable

  ROLES = %w[requester procurement_officer procurement_head approver inspector finance admin auditor].freeze
  # Roles that may see every department's cases (others see their own department only, NFR-05).
  ORGANIZATION_WIDE_ROLES = %w[admin auditor].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :department, optional: true
  belongs_to :position, optional: true
  belongs_to :person, optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :roles, with: ->(roles) { Array(roles).compact_blank.map(&:to_s).uniq }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 12 }, allow_nil: true
  validate :roles_are_known
  validate :department_required_for_department_roles

  scope :active, -> { where(active: true) }
  scope :with_role, ->(role) { where("? = ANY (roles)", role.to_s) }
  scope :ordered, -> { order(:name) }

  def self.role_label(role) = I18n.t("user_roles.#{role}")

  def role?(role) = roles.include?(role.to_s)

  def admin? = role?(:admin)

  def organization_wide? = roles.intersect?(ORGANIZATION_WIDE_ROLES)

  def role_labels = roles.map { |role| self.class.role_label(role) }

  private

  def roles_are_known
    unknown = roles - ROLES
    errors.add(:roles, "ไม่รู้จัก: #{unknown.join(', ')}") if unknown.any?
  end

  def department_required_for_department_roles
    return if roles.empty? || organization_wide? || department.present?

    errors.add(:department, "ต้องระบุส่วนงาน (ผู้ใช้เห็นเฉพาะเรื่องของส่วนงานตัวเอง)")
  end
end
