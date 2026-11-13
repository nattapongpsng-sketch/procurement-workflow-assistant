require "zip"

# Extracts readable text from a .docx for golden tests: one line per non-empty
# paragraph in document order (table cells and both text box copies included),
# whitespace collapsed.
module DocxText
  NS = { "w" => "http://schemas.openxmlformats.org/wordprocessingml/2006/main" }.freeze

  module_function

  def parts(bytes)
    entries = {}
    Zip::InputStream.open(StringIO.new(bytes)) do |zip|
      while (entry = zip.get_next_entry)
        next if entry.directory?

        data = zip.read
        entries[entry.name] = entry.name.end_with?(".xml", ".rels") ? data.force_encoding("UTF-8") : data
      end
    end
    entries
  end

  def document_xml(bytes) = Nokogiri::XML(parts(bytes).fetch("word/document.xml"))

  def lines(bytes)
    xml = document_xml(bytes)
    xml.xpath("//w:p", NS).filter_map do |paragraph|
      runs = paragraph.xpath(".//w:r", NS).select { |run| run.at_xpath("ancestor::w:p[1]", NS) == paragraph }
      text = runs.flat_map { |run| run.xpath("w:t|w:tab|w:br", NS).map { |n| n.name == "t" ? n.text : " " } }.join
      text = text.gsub(/[[:space:]]+/, " ").strip
      text unless text.empty?
    end
  end
end
