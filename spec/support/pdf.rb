RSpec.configure do |config|
  # PDF specs need LibreOffice + TH Sarabun New (installed in Docker and CI).
  # CI sets REQUIRE_PDF_SPECS=true so a missing LibreOffice fails instead of skipping.
  config.before(:each, :pdf) do
    next if PdfConverter.available?
    raise "REQUIRE_PDF_SPECS is set but LibreOffice is not installed" if ENV["REQUIRE_PDF_SPECS"] == "true"

    skip "LibreOffice ไม่ได้ติดตั้ง"
  end
end
