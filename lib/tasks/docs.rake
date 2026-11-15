namespace :docs do
  desc "Render every document of the sample case to tmp/samples/ for checking in Word (leaves the database unchanged)"
  task render_sample: :environment do
    out_dir = Rails.root.join("tmp/samples")
    FileUtils.mkdir_p(out_dir)
    evidence_key = nil
    written = []
    ActiveRecord::Base.transaction do
      # The result report cites the purchase request, so give the sample a letter number and date.
      procurement_case = SampleCases.purchase_request("request.doc_no" => "617", "request.doc_date" => "2026-07-15")
      evidence_key = ActiveStorage::Blob.find_signed(procurement_case.value("price.evidence"))&.key
      context = DocumentContext.build(procurement_case)
      procurement_case.workflow_template.document_templates.each do |document_template|
        document = GeneratedDocument.new(procurement_case:, document_template:)
        path = out_dir.join("#{document_template.code}_sample.docx")
        File.binwrite(path, DocumentGenerator.new(document).render(context))
        written << path
      end
      raise ActiveRecord::Rollback
    end
    ActiveStorage::Blob.service.delete(evidence_key) if evidence_key
    written.each { |path| puts "wrote #{path}" }
  end
end
