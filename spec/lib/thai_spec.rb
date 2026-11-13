require "rails_helper"

RSpec.describe Thai do
  describe ".baht_text" do
    {
      7990 => "เจ็ดพันเก้าร้อยเก้าสิบบาทถ้วน",
      6800 => "หกพันแปดร้อยบาทถ้วน",
      1_350_000 => "หนึ่งล้านสามแสนห้าหมื่นบาทถ้วน",
      500_000 => "ห้าแสนบาทถ้วน",
      50_000 => "ห้าหมื่นบาทถ้วน",
      0 => "ศูนย์บาทถ้วน",
      1 => "หนึ่งบาทถ้วน",
      10 => "สิบบาทถ้วน",
      11 => "สิบเอ็ดบาทถ้วน",
      20 => "ยี่สิบบาทถ้วน",
      21 => "ยี่สิบเอ็ดบาทถ้วน",
      101 => "หนึ่งร้อยเอ็ดบาทถ้วน",
      110 => "หนึ่งร้อยสิบบาทถ้วน",
      1_000_000 => "หนึ่งล้านบาทถ้วน",
      1_000_001 => "หนึ่งล้านเอ็ดบาทถ้วน",
      11_000_000 => "สิบเอ็ดล้านบาทถ้วน",
      21_000_021 => "ยี่สิบเอ็ดล้านยี่สิบเอ็ดบาทถ้วน",
      1_000_000_000_000 => "หนึ่งล้านล้านบาทถ้วน"
    }.each do |amount, words|
      it "reads #{amount} as #{words}" do
        expect(described_class.baht_text(amount)).to eq(words)
      end
    end

    it "reads satang" do
      expect(described_class.baht_text(BigDecimal("7990.50"))).to eq("เจ็ดพันเก้าร้อยเก้าสิบบาทห้าสิบสตางค์")
      expect(described_class.baht_text("0.25")).to eq("ยี่สิบห้าสตางค์")
      expect(described_class.baht_text("1.01")).to eq("หนึ่งบาทหนึ่งสตางค์")
      expect(described_class.baht_text("100.21")).to eq("หนึ่งร้อยบาทยี่สิบเอ็ดสตางค์")
    end

    it "rounds to the nearest satang" do
      expect(described_class.baht_text("10.005")).to eq("สิบบาทหนึ่งสตางค์")
    end

    it "rejects negative or missing amounts" do
      expect { described_class.baht_text(-1) }.to raise_error(ArgumentError)
      expect { described_class.baht_text(nil) }.to raise_error(ArgumentError)
      expect { described_class.baht_text("abc") }.to raise_error(ArgumentError)
    end
  end

  describe ".money" do
    it "formats whole baht with .- like PEA forms" do
      expect(described_class.money(7990)).to eq("7,990.-")
      expect(described_class.money(1_350_000)).to eq("1,350,000.-")
      expect(described_class.money(500)).to eq("500.-")
    end

    it "keeps satang when present" do
      expect(described_class.money(BigDecimal("7990.5"))).to eq("7,990.50")
      expect(described_class.money("844945.16")).to eq("844,945.16")
    end
  end

  describe ".date" do
    let(:date) { Date.new(2026, 7, 17) }

    it "formats the full Thai date in Buddhist Era" do
      expect(described_class.date(date)).to eq("17 กรกฎาคม 2569")
    end

    it "formats the short Thai date" do
      expect(described_class.date(date, format: :short)).to eq("17 ก.ค. 2569")
    end

    it "accepts ISO strings and times" do
      expect(described_class.date("2026-09-15")).to eq("15 กันยายน 2569")
      expect(described_class.date(Time.zone.local(2026, 1, 1, 9), format: :short)).to eq("1 ม.ค. 2569")
    end

    it "returns nil for blank input" do
      expect(described_class.date(nil)).to be_nil
      expect(described_class.date("")).to be_nil
    end
  end

  describe ".buddhist_year" do
    it "adds 543" do
      expect(described_class.buddhist_year(Date.new(2026, 7, 17))).to eq(2569)
    end
  end

  describe ".doc_number" do
    it "builds an outgoing letter number" do
      expect(described_class.doc_number("สชก.(บก-ท)", 617, 2569)).to eq("สชก.(บก-ท) 617/2569")
    end

    it "leaves a gap to fill by hand when the number is not issued yet" do
      expect(described_class.doc_number("สชก.(บก-ท)", nil, 2569)).to eq("สชก.(บก-ท)         /2569")
    end
  end
end
