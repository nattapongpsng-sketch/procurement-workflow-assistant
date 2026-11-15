require "rails_helper"

RSpec.describe PdfConverter do
  # LibreOffice writes object names uncompressed, so these checks work on raw bytes.
  def embedded_fonts(pdf) = pdf.b.scan(%r{/FontName\s*/[A-Z]{6}\+([^\s/>]+)}).flatten.uniq
  def page_sizes(pdf) = pdf.b.scan(%r{/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]}).uniq

  describe "real documents", :pdf do
    around { |example| travel_to(Time.zone.local(2026, 11, 13, 10)) { example.run } }

    let!(:procurement_case) { build_purchase_request_case("request.doc_no" => "617", "request.doc_date" => "2026-07-15") }

    %w[purchase_request result_report].each do |code|
      it "turns #{code} into an A4 PDF with TH Sarabun New embedded" do
        template = DocumentTemplate.find_by!(code:)
        docx = DocumentGenerator.new(GeneratedDocument.new(procurement_case:, document_template: template))
                                .render(DocumentContext.build(procurement_case))
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        pdf = described_class.call(docx)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

        expect(pdf).to start_with("%PDF-")
        expect(embedded_fonts(pdf)).to include("THSarabunNew")
        expect(page_sizes(pdf).map { |w, h| [ w.to_f.round, h.to_f.round ] }).to eq([ [ 595, 842 ] ])
        expect(elapsed).to be < 10 # NFR-04 target is 5 s per set; a cold LibreOffice start is slower in CI
      end
    end

    it "attaches the PDF next to the .docx when generating" do
      document = DocumentGenerator.call(GeneratedDocument.create!(procurement_case:,
                                                                  document_template: DocumentTemplate.find_by!(code: "purchase_request")))

      expect(document.pdf).to be_attached
      expect(document.pdf.filename.to_s).to end_with(".pdf")
    end
  end

  it "reports a clear error when LibreOffice is missing" do
    allow(described_class).to receive(:binary).and_return(nil)

    expect { described_class.call("x") }.to raise_error(PdfConverter::Unavailable, /LibreOffice/)
  end

  it "fails document generation when a PDF is required but cannot be made" do
    allow(described_class).to receive(:binary).and_return(nil)
    allow(DocumentGenerator).to receive(:pdf_required?).and_return(true)
    kase = build_purchase_request_case
    document = GeneratedDocument.create!(procurement_case: kase, document_template: DocumentTemplate.find_by!(code: "purchase_request"))

    expect { DocumentGenerator.call(document) }.to raise_error(PdfConverter::Unavailable)
    expect(document.reload).to be_failed
  end
end
