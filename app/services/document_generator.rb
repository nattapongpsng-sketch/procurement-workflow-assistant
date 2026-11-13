# Renders one document template for a case with Sablon and stores the result
# (plus the exact data it used) as a GeneratedDocument.
class DocumentGenerator
  class Error < StandardError; end

  def self.call(generated_document) = new(generated_document).call

  # Creates the record and queues rendering on Solid Queue.
  def self.enqueue(procurement_case, document_template)
    GeneratedDocument.create!(procurement_case:, document_template:).tap do |document|
      GenerateDocumentJob.perform_later(document)
    end
  end

  def initialize(generated_document)
    @document = generated_document
  end

  def call
    @document.update!(status: :generating, error_message: nil)
    procurement_case = @document.procurement_case
    @document.data_snapshot = DocumentContext.build(procurement_case, for_snapshot: true)
    bytes = render(DocumentContext.build(procurement_case))
    @document.file.attach(io: StringIO.new(bytes), filename: @document.filename, content_type: SeedLoader::DOCX_TYPE)
    @document.update!(status: :succeeded, generated_at: Time.current)
    @document
  rescue StandardError => e
    @document.update!(status: :failed, error_message: "#{e.class}: #{e.message}")
    raise
  end

  # Renders to a String of .docx bytes. Uses the template stored in Active
  # Storage; falls back to the file in the repo when none is attached yet.
  def render(context)
    document_template = @document.document_template
    if document_template.docx_file.attached?
      document_template.docx_file.open { |file| Sablon.template(file.path).render_to_string(context) }
    else
      path = document_template.source_path
      raise Error, "ไม่พบไฟล์ template #{path}" unless File.file?(path)

      Sablon.template(path.to_s).render_to_string(context)
    end
  end
end
