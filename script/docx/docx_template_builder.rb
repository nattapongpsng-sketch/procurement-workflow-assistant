require "nokogiri"
require "zip"
require "zlib"

# Small, strict helper for turning a real .docx form into a Sablon template.
# Each rule must match the expected number of paragraphs or the build aborts,
# so a changed source file never produces a silently broken template.
class DocxTemplateBuilder
  W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main".freeze
  R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships".freeze
  NS = { "w" => W, "r" => R, "a" => "http://schemas.openxmlformats.org/drawingml/2006/main" }.freeze
  DOCUMENT = "word/document.xml".freeze

  Field = Struct.new(:expr)

  def self.placeholder_png(width, height, gray: 0xE5)
    row = ([ 0 ] + [ gray ] * (width * 3)).pack("C*")
    chunk = ->(type, data) { [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N") }
    "\x89PNG\r\n\x1A\n".b +
      chunk.call("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("NNCCCCC")) +
      chunk.call("IDAT", Zlib::Deflate.deflate(row * height, Zlib::BEST_COMPRESSION)) +
      chunk.call("IEND", "")
  end

  def initialize(source, target)
    raise ArgumentError, "source not found: #{source}" unless File.file?(source)

    @source = source
    @target = target
  end

  def build
    @entries = Zip::File.open(@source) { |zip| zip.entries.to_h { |e| [ e.name, e.get_input_stream.read ] } }
    @doc = Nokogiri::XML(@entries.fetch(DOCUMENT))
    yield self
    @entries[DOCUMENT] = @doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
    write
  end

  def apply(rule)
    matches = paragraphs.select { |p| text_of(p).match?(rule[:match]) }
    expected = rule[:expect] || (rule[:nth] ? nil : 1)
    if expected && matches.size != expected
      raise "rule #{rule[:match].inspect}: expected #{expected} paragraph(s), found #{matches.size}"
    end

    targets = rule[:nth] ? matches.values_at(*rule[:nth]) : matches
    raise "rule #{rule[:match].inspect}: nth out of range" if targets.any?(&:nil?)

    targets.each do |paragraph|
      if rule[:delete]
        paragraph.remove
        next
      end
      target = rule[:cell_after] ? next_cell_paragraph(paragraph) : paragraph
      rebuild(target, rule[:replace], style_source: paragraph)
    end
  end

  # Wraps the image that uses `media` in Sablon image + conditional fields so the
  # case's own picture replaces it, and the picture disappears when there is none.
  def wrap_image(media:, field:)
    rels = Nokogiri::XML(@entries.fetch("word/_rels/document.xml.rels"))
    rel = rels.root.element_children.find { |r| r["Target"] == media.delete_prefix("word/") }
    raise "no relationship for #{media}" unless rel

    blip = @doc.at_xpath("//a:blip[@r:embed='#{rel['Id']}']", NS) or raise "image #{media} not used in document"
    run = blip.at_xpath("ancestor::w:r[1]", NS)
    rpr = run.at_xpath("w:rPr", NS)
    run.add_previous_sibling(field_node("#{field}:if", rpr))
    run.add_previous_sibling(field_node("@#{field}:start", rpr))
    run.add_next_sibling(field_node("#{field}:endIf", rpr))
    run.add_next_sibling(field_node("@#{field}:end", rpr))
  end

  def replace_media(name, bytes)
    raise "no media #{name}" unless @entries.key?(name)

    @entries[name] = bytes
  end

  # Removes personal data left by whoever last edited the source file.
  def scrub_metadata!
    core = Nokogiri::XML(@entries.fetch("docProps/core.xml"))
    core.root.element_children.each do |node|
      case node.name
      when "creator", "lastModifiedBy" then node.content = "Procurement Workflow Assistant"
      when "lastPrinted", "title" then node.remove
      end
    end
    @entries["docProps/core.xml"] = core.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
    @entries["docProps/app.xml"] = @entries.fetch("docProps/app.xml").sub(%r{<Company>[^<]*</Company>}, "<Company></Company>")
  end

  private

  def paragraphs = @doc.xpath("//w:p", NS)

  # Runs that belong to this paragraph (not to a text box nested inside it).
  def own_runs(paragraph)
    paragraph.xpath(".//w:r", NS).select { |run| run.at_xpath("ancestor::w:p[1]", NS) == paragraph }
  end

  def text_of(paragraph)
    own_runs(paragraph).flat_map do |run|
      run.element_children.map do |node|
        case node.name
        when "t" then node.text
        when "tab" then "\t"
        else ""
        end
      end
    end.join
  end

  def next_cell_paragraph(paragraph)
    cell = paragraph.at_xpath("ancestor::w:tc[1]", NS) or raise "not in a table cell"
    cell.at_xpath("following-sibling::w:tc[1]/w:p", NS) or raise "no next cell"
  end

  def rebuild(paragraph, replacements, style_source:)
    original = text_of(paragraph)
    segments = replacements.inject([ original ]) do |current, (pattern, replacement)|
      hits = 0
      result = current.flat_map do |segment|
        next [ segment ] unless segment.is_a?(String) && (match = pattern.match(segment))

        hits += 1
        [ match.pre_match, *replacement, match.post_match ].reject { |part| part == "" }
      end
      raise "pattern #{pattern.inspect} matched #{hits} time(s) in: #{original}" unless hits == 1

      result
    end

    rpr = run_properties(paragraph) || run_properties(style_source)
    paragraph.element_children.each { |child| child.remove unless child.name == "pPr" }
    segments.each do |segment|
      if segment.is_a?(Field)
        paragraph.add_child(field_node("=#{segment.expr}", rpr))
      else
        segment.split(/(\t)/).reject(&:empty?).each { |part| paragraph.add_child(text_run(part, rpr)) }
      end
    end
  end

  def run_properties(paragraph)
    own_runs(paragraph).find { |run| run.at_xpath("w:t", NS) }&.at_xpath("w:rPr", NS)
  end

  def text_run(text, rpr)
    run = node("w:r")
    run.add_child(rpr.dup) if rpr
    run.add_child(text == "\t" ? node("w:tab") : text_node(text))
    run
  end

  def field_node(expr, rpr)
    field = node("w:fldSimple")
    field["w:instr"] = " MERGEFIELD #{expr} \\* MERGEFORMAT "
    field.add_child(text_run("«#{expr.delete_prefix('=')}»", rpr))
    field
  end

  def text_node(text)
    t = node("w:t")
    t["xml:space"] = "preserve"
    t.content = text
    t
  end

  def node(name)
    element = Nokogiri::XML::Node.new(name.delete_prefix("w:"), @doc)
    element.namespace = @doc.root.namespace_definitions.find { |ns| ns.href == W }
    element
  end

  def write
    File.binwrite(@target, Zip::OutputStream.write_buffer do |zip|
      @entries.each do |name, bytes|
        zip.put_next_entry(name)
        zip.write(bytes)
      end
    end.string)
  end
end
