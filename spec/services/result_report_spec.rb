require "rails_helper"

# Golden test for รายงานผลการพิจารณาและอนุมัติสั่งซื้อ. The template was rebuilt from the
# PDF (no original .docx — OPEN_QUESTIONS Q28), so the golden text follows the PDF.
# Regenerate: UPDATE_GOLDEN=1 bundle exec rspec spec/services/result_report_spec.rb
RSpec.describe "Result report generation" do
  golden = Rails.root.join("spec/fixtures/golden/result_report.txt")

  around { |example| travel_to(Time.zone.local(2026, 11, 13, 10)) { example.run } }

  let(:procurement_case) { build_purchase_request_case("request.doc_no" => "617", "request.doc_date" => "2026-07-15") }
  let(:document_template) { DocumentTemplate.find_by!(code: "result_report") }
  let(:bytes) do
    DocumentGenerator.call(GeneratedDocument.create!(procurement_case:, document_template:)).file.download
  end

  it "matches the golden text of the PDF form" do
    lines = DocxText.lines(bytes)
    File.write(golden, lines.join("\n") + "\n") if ENV["UPDATE_GOLDEN"]

    expect(lines).to eq(File.read(golden).split("\n"))
  end

  it "is a well-formed .docx with the form's logo and no leftover fields or pictures" do
    parts = DocxText.parts(bytes)

    parts.select { |name, _| name.end_with?(".xml", ".rels") }.each do |name, xml|
      expect { Nokogiri::XML(xml) { |config| config.strict } }.not_to raise_error, "#{name} is not well-formed"
    end
    expect(parts["word/document.xml"]).not_to include("MERGEFIELD", "«", "»")
    expect(DocxText.document_xml(bytes).xpath("//w:drawing", DocxText::NS).size).to eq(1)
  end

  it "uses the same font as the purchase request form" do
    run = DocxText.document_xml(bytes).xpath("//w:r[w:t[contains(., 'ผลการพิจารณาปรากฏว่า')]]", DocxText::NS).first

    expect(run.at_xpath("w:rPr/w:rFonts/@w:ascii", DocxText::NS).value).to eq("TH Sarabun New")
  end
end
