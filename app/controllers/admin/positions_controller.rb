class Admin::PositionsController < Admin::BaseController
  before_action :set_position, only: %i[edit update]

  def index
    @positions = current_organization.positions.ordered
  end

  def new
    @position = current_organization.positions.new
  end

  def create
    @position = current_organization.positions.new(position_params)
    if @position.save
      redirect_to admin_positions_path, notice: "เพิ่มตำแหน่ง #{@position.title} แล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @position.update(position_params)
      redirect_to admin_positions_path, notice: "บันทึกตำแหน่ง #{@position.title} แล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_position = @position = current_organization.positions.find(params[:id])

  def position_params = params.expect(position: %i[title short_title])
end
