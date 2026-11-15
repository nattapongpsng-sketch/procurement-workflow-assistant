require "rails_helper"

# Golden test: the generated purchase request must read exactly like the real
# form (spec/fixtures/golden/purchase_request.txt). Deviations from the source
# form are listed in spec/fixtures/golden/README.md.
# Regenerate after an intended change: UPDATE_GOLDEN=1 bundle exec rspec spec/services/document_generator_spec.rb
RSpec.describe DocumentGenerator do
  GOLDEN = Rails.root.join("spec/fixtures/golden/purchase_request.txt")

  around { |example| travel_to(Time.zone.local(2026, 11, 13, 10)) { example.run } }

  let(:procurement_case) { build_purchase_request_case }
  let(:document_template) { DocumentTemplate.find_by!(code: "purchase_request") }
  let(:generated) { described_class.call(GeneratedDocument.create!(procurement_case:, document_template:)) }
  let(:bytes) { generated.file.download }

  it "matches the golden text of the real form" do
    lines = DocxText.lines(bytes)
    File.write(GOLDEN, lines.join("\n") + "\n") if ENV["UPDATE_GOLDEN"]

    expect(lines).to eq(File.read(GOLDEN).split("\n"))
  end

  it "produces a well-formed .docx with no leftover merge fields" do
    parts = DocxText.parts(bytes)

    expect(parts.keys).to include("[Content_Types].xml", "word/document.xml", "word/styles.xml")
    parts.select { |name, _| name.end_with?(".xml", ".rels") }.each do |name, xml|
      expect { Nokogiri::XML(xml) { |config| config.strict } }.not_to raise_error, "#{name} is not well-formed"
    end
    expect(parts["word/document.xml"]).not_to include("MERGEFIELD", "«", "»")
  end

  it "formats inserted values exactly like the surrounding form text" do
    xml = DocxText.document_xml(bytes)
    value_run = xml.xpath("//w:r[w:t[contains(., 'เจ็ดพันเก้าร้อยเก้าสิบบาทถ้วน')]]", DocxText::NS).first
    static_run = value_run.parent.xpath("w:r[w:t[contains(., 'รวมภาษีมูลค่าเพิ่ม')]]", DocxText::NS).first

    expect(value_run.at_xpath("w:rPr/w:rFonts/@w:ascii", DocxText::NS).value).to eq("TH Sarabun New")
    expect(value_run.at_xpath("w:rPr", DocxText::NS).to_xml).to eq(static_run.at_xpath("w:rPr", DocxText::NS).to_xml)
  end

  it "embeds the case's price evidence in place of the placeholder" do
    parts = DocxText.parts(bytes)
    evidence = File.binread(PurchaseRequestFixture::EVIDENCE)

    expect(parts.values).to include(evidence)
    expect(parts.keys.grep(%r{\Aword/media/})).to include("word/media/image1.jpeg")
  end

  it "drops the evidence picture when the case has none" do
    kase = build_purchase_request_case("price.evidence" => nil)
    document = described_class.call(GeneratedDocument.create!(procurement_case: kase, document_template:))

    expect(DocxText.document_xml(document.file.download).xpath("//w:drawing", DocxText::NS).size).to eq(3)
  end

  it "uses the USD clause when the price is in dollars" do
    kase = build_purchase_request_case("price.currency" => "USD", "price.thb_amount" => nil,
                                       "price.foreign_amount" => "200", "price.exchange_rate" => "34")
    document = described_class.call(GeneratedDocument.create!(procurement_case: kase, document_template:))
    text = DocxText.lines(document.file.download).join("\n")

    expect(text).to include("6,800.- บาท (หกพันแปดร้อยบาทถ้วน) (รวมภาษีมูลค่าเพิ่ม) (200 USD โดยคิด 1 USD = 34 บาท) (เอกสารแนบ 3)")
  end

  it "stores the data snapshot and marks the document as succeeded" do
    expect(generated).to be_succeeded
    expect(generated.generated_at).to be_present
    expect(generated.data_snapshot.dig("budget", "total_text")).to eq("เจ็ดพันเก้าร้อยเก้าสิบบาทถ้วน")
    expect(generated.data_snapshot.dig("price", "evidence", "filename")).to eq("price_evidence.png")
  end

  it "records failures on the document" do
    document = GeneratedDocument.create!(procurement_case:, document_template:)
    allow(DocumentContext).to receive(:build).and_raise(ArgumentError, "boom")

    expect { described_class.call(document) }.to raise_error(ArgumentError)
    expect(document.reload).to be_failed
    expect(document.error_message).to include("boom")
  end
end

RSpec.describe GenerateDocumentJob do
  include ActiveJob::TestHelper

  it "renders the document in the background" do
    kase = build_purchase_request_case
    template = DocumentTemplate.find_by!(code: "purchase_request")

    document = perform_enqueued_jobs { DocumentGenerator.enqueue(kase, template) }

    expect(document.reload).to be_succeeded
    expect(document.file).to be_attached
  end
end
