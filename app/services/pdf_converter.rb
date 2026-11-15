require "open3"
require "timeout"

# Converts .docx bytes to PDF with LibreOffice headless, so PDFs keep the exact
# layout of the real form templates (design principle 5) with fonts embedded
# (Requirement FR-21, NFR-04). Each conversion uses its own LibreOffice profile
# so several jobs can convert at the same time.
class PdfConverter
  class Error < StandardError; end
  class Unavailable < Error; end

  BINARIES = %w[soffice libreoffice].freeze
  TIMEOUT = 60

  def self.binary
    return ENV["SOFFICE_PATH"] if ENV["SOFFICE_PATH"].present?

    BINARIES.lazy.flat_map { |name| ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |dir| File.join(dir, name) } }
            .find { |path| File.executable?(path) }
  end

  def self.available? = binary.present?

  def self.call(docx_bytes) = new.call(docx_bytes)

  def call(docx_bytes)
    binary = self.class.binary or raise Unavailable, "ไม่พบ LibreOffice (soffice) สำหรับแปลง PDF"

    Dir.mktmpdir("pdf") do |dir|
      input = File.join(dir, "document.docx")
      File.binwrite(input, docx_bytes)
      command = [ binary, "-env:UserInstallation=file://#{dir}/profile", "--headless", "--norestore",
                  "--nolockcheck", "--convert-to", "pdf:writer_pdf_Export", "--outdir", dir, input ]
      output, status = run(command)
      pdf = File.join(dir, "document.pdf")
      raise Error, "แปลง PDF ไม่สำเร็จ: #{output.to_s.strip.last(500)}" unless status&.success? && File.file?(pdf)

      File.binread(pdf)
    end
  end

  private

  def run(command)
    Timeout.timeout(TIMEOUT) { Open3.capture2e(*command) }
  rescue Timeout::Error
    raise Error, "แปลง PDF เกิน #{TIMEOUT} วินาที"
  end
end
