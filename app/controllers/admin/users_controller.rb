class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[edit update]

  def index
    @users = User.includes(:department, :position).ordered
  end

  def new
    @user = User.new(active: true)
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "เพิ่มผู้ใช้ #{@user.name} แล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attributes = user_params
    attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?
    if self_lockout?(attributes)
      @user.assign_attributes(attributes)
      @user.errors.add(:base, "เอาสิทธิ์ผู้ดูแลระบบหรือปิดใช้งานบัญชีของตัวเองไม่ได้ ให้ผู้ดูแลคนอื่นทำแทน")
      render :edit, status: :unprocessable_entity
    elsif @user.update(attributes)
      redirect_to admin_users_path, notice: "บันทึกข้อมูล #{@user.name} แล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user = @user = User.find(params[:id])

  def user_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation, :department_id, :position_id,
                          :person_id, :active, { roles: [] } ])
  end

  # An admin cannot remove their own admin role or deactivate themselves (avoids locking everyone out).
  def self_lockout?(attributes)
    return false unless @user == Current.user

    roles = Array(attributes[:roles]).compact_blank
    !roles.include?("admin") || attributes[:active] == "0"
  end
end
