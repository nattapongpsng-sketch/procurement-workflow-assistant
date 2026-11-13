namespace :docs do
  desc "Render the sample purchase request to tmp/samples/ for checking in Word (leaves the database unchanged)"
  task render_sample: :environment do
    out = Rails.root.join("tmp/samples/purchase_request_sample.docx")
    FileUtils.mkdir_p(out.dirname)
    evidence_key = nil
    ActiveRecord::Base.transaction do
      procurement_case = SampleCases.purchase_request
      evidence_key = ActiveStorage::Blob.find_signed(procurement_case.value("price.evidence"))&.key
      document = GeneratedDocument.new(procurement_case:,
                                       document_template: DocumentTemplate.find_by!(code: "purchase_request"))
      File.binwrite(out, DocumentGenerator.new(document).render(DocumentContext.build(procurement_case)))
      raise ActiveRecord::Rollback
    end
    ActiveStorage::Blob.service.delete(evidence_key) if evidence_key
    puts "wrote #{out}"
  end
end
