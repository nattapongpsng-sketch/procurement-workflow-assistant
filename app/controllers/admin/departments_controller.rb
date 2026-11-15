class Admin::DepartmentsController < Admin::BaseController
  before_action :set_department, only: %i[edit update]

  def index
    @departments = current_organization.departments.includes(:parent).ordered
  end

  def new
    @department = current_organization.departments.new(active: true)
  end

  def create
    @department = current_organization.departments.new(department_params)
    if @department.save
      redirect_to admin_departments_path, notice: "เพิ่มส่วนงาน #{@department.name} แล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @department.update(department_params)
      redirect_to admin_departments_path, notice: "บันทึกส่วนงาน #{@department.name} แล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_department = @department = current_organization.departments.find(params[:id])

  def department_params = params.expect(department: %i[name code parent_id active])
end
