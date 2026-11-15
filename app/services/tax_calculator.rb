# Totals, VAT and withholding tax for a list of line items (Requirement FR-09, FR-19, NFR-02).
#
# Rounding rules (pending finance confirmation, OPEN_QUESTIONS Q36):
# - line amount = quantity × unit price, kept exact (no rounding per line)
# - VAT is computed once on the summed amount and rounded to satang, half-up
#     exclusive: VAT = sum × rate                 total = sum + VAT
#     inclusive: VAT = sum × rate / (1 + rate)    base  = sum - VAT
#     none     : no VAT (vendor not VAT-registered)
# - withholding tax = base before VAT × rate, rounded to satang half-up, only when the
#   base reaches the income type's minimum amount; net payable = total - withholding
class TaxCalculator
  VAT_MODES = %i[exclusive inclusive none].freeze
  DEFAULT_VAT_RATE = BigDecimal("0.07")

  Line = Data.define(:name, :quantity, :unit_price, :amount)
  Result = Data.define(:lines, :subtotal, :vat, :total, :withholding, :net_payable, :vat_mode, :vat_rate,
                       :withholding_type) do
    def total_text = Thai.baht_text(total)
    def vat_text = Thai.baht_text(vat)
    def net_payable_text = Thai.baht_text(net_payable)
  end

  def self.call(...) = new(...).call

  def self.round(amount) = amount.round(2, BigDecimal::ROUND_HALF_UP)

  def initialize(lines:, vat_mode:, vat_rate: DEFAULT_VAT_RATE, withholding: nil)
    @lines = lines
    @vat_mode = vat_mode.to_sym
    @vat_rate = Thai.decimal(vat_rate)
    @withholding_type = withholding.is_a?(String) || withholding.is_a?(Symbol) ? WithholdingTaxType.active.find_by!(code: withholding) : withholding
  end

  def call
    raise ArgumentError, "ไม่รู้จักวิธีคิด VAT: #{@vat_mode}" unless VAT_MODES.include?(@vat_mode)
    raise ArgumentError, "ต้องมีรายการอย่างน้อย 1 รายการ" if @lines.blank?

    lines = @lines.map { |line| build_line(line.to_h.symbolize_keys) }
    sum = lines.sum(&:amount)
    subtotal, vat, total = vat_breakdown(sum)
    withholding = withholding_for(subtotal)

    Result.new(lines:, subtotal:, vat:, total:, withholding:, net_payable: total - withholding,
               vat_mode: @vat_mode, vat_rate: @vat_rate, withholding_type: @withholding_type)
  end

  private

  def build_line(line)
    quantity = Thai.decimal(line.fetch(:quantity))
    unit_price = Thai.decimal(line.fetch(:unit_price))
    raise ArgumentError, "จำนวนต้องมากกว่า 0 (#{line[:name]})" unless quantity.positive?
    raise ArgumentError, "ราคาต่อหน่วยติดลบไม่ได้ (#{line[:name]})" if unit_price.negative?

    Line.new(name: line[:name], quantity:, unit_price:, amount: quantity * unit_price)
  end

  def vat_breakdown(sum)
    case @vat_mode
    when :exclusive
      subtotal = self.class.round(sum)
      vat = self.class.round(sum * @vat_rate)
      [ subtotal, vat, subtotal + vat ]
    when :inclusive
      total = self.class.round(sum)
      vat = self.class.round(sum * @vat_rate / (1 + @vat_rate))
      [ total - vat, vat, total ]
    else
      total = self.class.round(sum)
      [ total, BigDecimal(0), total ]
    end
  end

  def withholding_for(base)
    return BigDecimal(0) if @withholding_type.nil? || base < @withholding_type.minimum_amount

    self.class.round(base * @withholding_type.rate)
  end
end
