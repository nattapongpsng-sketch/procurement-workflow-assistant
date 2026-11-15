require "rails_helper"

# Rounding rules (NFR-02): line amounts are exact; VAT is computed once on the total and
# rounded to satang half-up; withholding tax is computed on the amount before VAT, rounded
# to satang half-up. Pending finance confirmation (OPEN_QUESTIONS Q36).
RSpec.describe TaxCalculator do
  def line(quantity, unit_price, name: "รายการ") = { name:, quantity:, unit_price: }

  def calc(lines, **options) = described_class.call(lines:, **options)

  describe "VAT" do
    it "adds 7% VAT on top when prices exclude VAT" do
      result = calc([ line(1, "7990") ], vat_mode: :exclusive)

      expect(result.subtotal).to eq(BigDecimal("7990.00"))
      expect(result.vat).to eq(BigDecimal("559.30"))
      expect(result.total).to eq(BigDecimal("8549.30"))
    end

    it "extracts VAT when prices already include it" do
      result = calc([ line(1, "7990") ], vat_mode: :inclusive)

      expect(result.total).to eq(BigDecimal("7990.00"))
      expect(result.vat).to eq(BigDecimal("522.71")) # 7990 × 7 / 107 = 522.710…
      expect(result.subtotal).to eq(BigDecimal("7467.29"))
    end

    it "charges no VAT for vendors not registered for VAT" do
      result = calc([ line(2, "150") ], vat_mode: :none)

      expect([ result.subtotal, result.vat, result.total ]).to eq([ 300, 0, 300 ].map { BigDecimal(it) })
    end

    it "rounds VAT once on the total, half-up, not per line" do
      lines = [ line(1, "0.05"), line(1, "0.05"), line(1, "0.05") ] # per-line VAT 0.0035 each
      result = calc(lines, vat_mode: :exclusive)

      expect(result.vat).to eq(BigDecimal("0.01")) # 0.15 × 7% = 0.0105 → 0.01
      expect(calc([ line(1, "0.50") ], vat_mode: :exclusive).vat).to eq(BigDecimal("0.04")) # 0.035 → 0.04 (half-up)
    end

    it "keeps exact line amounts for fractional quantities" do
      result = calc([ line("12.5", "39.99", name: "น้ำมันดีเซล (ลิตร)") ], vat_mode: :inclusive)

      expect(result.lines.first.amount).to eq(BigDecimal("499.875"))
      expect(result.total).to eq(BigDecimal("499.88"))
    end

    it "uses the configured VAT rate" do
      expect(calc([ line(1, "100") ], vat_mode: :exclusive, vat_rate: "0.10").vat).to eq(BigDecimal("10.00"))
    end
  end

  describe "withholding tax" do
    let!(:services) { WithholdingTaxType.create!(code: "services", name: "ค่าบริการ", rate: "0.03", minimum_amount: 1000) }

    it "withholds on the amount before VAT and reduces the amount paid" do
      result = calc([ line(1, "10000") ], vat_mode: :exclusive, withholding: services)

      expect(result.total).to eq(BigDecimal("10700.00"))
      expect(result.withholding).to eq(BigDecimal("300.00"))
      expect(result.net_payable).to eq(BigDecimal("10400.00"))
    end

    it "uses the base before VAT for VAT-inclusive prices" do
      result = calc([ line(1, "10700") ], vat_mode: :inclusive, withholding: services)

      expect(result.subtotal).to eq(BigDecimal("10000.00"))
      expect(result.withholding).to eq(BigDecimal("300.00"))
    end

    it "does not withhold below the minimum amount" do
      result = calc([ line(1, "999.99") ], vat_mode: :none, withholding: services)

      expect(result.withholding).to eq(0)
      expect(result.net_payable).to eq(result.total)
    end

    it "accepts the income type code" do
      expect(calc([ line(1, "2000") ], vat_mode: :none, withholding: "services").withholding).to eq(BigDecimal("60.00"))
    end
  end

  describe "amounts in words" do
    it "gives the Thai words for the total" do
      expect(calc([ line(1, "7990") ], vat_mode: :inclusive).total_text).to eq("เจ็ดพันเก้าร้อยเก้าสิบบาทถ้วน")
    end
  end

  describe "invalid input" do
    it "rejects empty lists, negative values and unknown VAT modes" do
      expect { calc([], vat_mode: :none) }.to raise_error(ArgumentError, /รายการ/)
      expect { calc([ line(-1, "10") ], vat_mode: :none) }.to raise_error(ArgumentError, /จำนวน/)
      expect { calc([ line(1, "-10") ], vat_mode: :none) }.to raise_error(ArgumentError, /ราคา/)
      expect { calc([ line(1, "10") ], vat_mode: :sometimes) }.to raise_error(ArgumentError, /VAT/)
    end
  end
end
