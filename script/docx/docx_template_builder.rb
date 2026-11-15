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
  # Child order of w:pPr required by the WordprocessingML schema (CT_PPr).
  PPR_ORDER = %w[pStyle keepNext keepLines pageBreakBefore framePr widowControl numPr suppressLineNumbers pBdr shd
                 tabs suppressAutoHyphens kinsoku wordWrap overflowPunct topLinePunct autoSpaceDE autoSpaceDN bidi
                 adjustRightInd snapToGrid spacing ind contextualSpacing mirrorIndents suppressOverlap jc
                 textDirection textAlignment textboxTightWrap outlineLvl divId cnfStyle rPr sectPr pPrChange].freeze

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

  # The single body-level paragraph whose text matches `pattern`.
  def paragraph(pattern)
    matches = paragraphs.select { |p| text_of(p).match?(pattern) }
    raise "expected 1 paragraph matching #{pattern.inspect}, found #{matches.size}" unless matches.size == 1

    matches.first
  end

  # Paragraph and run properties of `paragraph`, to style new paragraphs like existing ones.
  def styles_of(paragraph)
    { ppr: paragraph.at_xpath("w:pPr", NS)&.dup, rpr: run_properties(paragraph)&.dup }
  end

  # Removes every body element after `node` except the section properties.
  def remove_body_after(node)
    node.xpath("following-sibling::*").each { |sibling| sibling.remove unless sibling.name == "sectPr" }
  end

  # Appends a paragraph at the end of the body (before sectPr), styled with a copy
  # of `ppr`. `ppr_set` replaces paragraph properties, e.g. { "ind" => { "left" => "850" } }.
  def append_paragraph(segments, ppr:, rpr:, ppr_set: {})
    paragraph = node("w:p")
    if ppr
      props = ppr.dup
      ppr_set.each do |name, attrs|
        props.xpath("w:#{name}", NS).each(&:remove)
        element = node("w:#{name}")
        attrs.each { |key, value| element["w:#{key}"] = value }
        # Insert at the position the schema requires (Word rejects out-of-order pPr children).
        rank = PPR_ORDER.index(name) or raise "unknown pPr element #{name}"
        anchor = props.element_children.find { |child| (PPR_ORDER.index(child.name) || PPR_ORDER.size) > rank }
        anchor ? anchor.add_previous_sibling(element) : props.add_child(element)
      end
      paragraph.add_child(props)
    end
    Array(segments).each do |segment|
      if segment.is_a?(Field)
        paragraph.add_child(field_node("=#{segment.expr}", rpr))
      else
        segment.split(/(\t)/).reject(&:empty?).each { |part| paragraph.add_child(text_run(part, rpr)) }
      end
    end
    @doc.at_xpath("//w:body/w:sectPr", NS).add_previous_sibling(paragraph)
    paragraph
  end

  # Signature text boxes: widen to `width_emu` (keeping the right edge for boxes in the
  # right half of the column), drop the outline and let the box grow with its text, so
  # long names and positions are never cut off. Updates the VML fallback copy too.
  def restyle_text_boxes(width_emu:, column_width_emu:)
    ns = @doc.root.namespaces.merge(
      "xmlns:wp" => "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
      "xmlns:wps" => "http://schemas.microsoft.com/office/word/2010/wordprocessingShape",
      "xmlns:a" => "http://schemas.openxmlformats.org/drawingml/2006/main",
      "xmlns:mc" => "http://schemas.openxmlformats.org/markup-compatibility/2006",
      "xmlns:v" => "urn:schemas-microsoft-com:vml"
    ).transform_keys { |key| key.delete_prefix("xmlns:") }
    anchors = @doc.xpath("//wp:anchor[.//wps:txbx]", ns)
    raise "no text boxes found" if anchors.empty?

    anchors.each do |anchor|
      extent = anchor.at_xpath("wp:extent", ns)
      offset = anchor.at_xpath("wp:positionH/wp:posOffset", ns)
      old_width = extent["cx"].to_i
      left = offset.text.to_i
      new_left = left + (old_width / 2) > column_width_emu / 2 ? left + old_width - width_emu : left
      new_left = new_left.clamp(0, column_width_emu - width_emu)

      extent["cx"] = width_emu.to_s
      anchor.at_xpath(".//a:xfrm/a:ext", ns)["cx"] = width_emu.to_s
      offset.content = new_left.to_s
      line = anchor.at_xpath(".//wps:spPr/a:ln", ns)
      line.children.remove
      line.add_child(Nokogiri::XML::Node.new("noFill", @doc).tap { |n| n.namespace = line.namespace })
      autofit = anchor.at_xpath(".//wps:bodyPr/a:noAutofit", ns)
      autofit.name = "spAutoFit" if autofit

      shape = anchor.at_xpath("ancestor::mc:AlternateContent[1]/mc:Fallback//v:shape", ns)
      next unless shape

      style = shape["style"]
      style = style.sub(/width:[\d.]+pt/, "width:#{(width_emu / 12_700.0).round(2)}pt")
      style = style.sub(/margin-left:[\d.]+pt/, "margin-left:#{(new_left / 12_700.0).round(2)}pt")
      shape["style"] = style
      shape["stroked"] = "f"
    end
  end

  # Removes empty paragraphs at the end of the body (they only push a blank page out).
  def remove_trailing_empty_paragraphs
    body = @doc.at_xpath("//w:body", NS)
    body.element_children.reverse_each do |node|
      next if node.name == "sectPr"
      break unless node.name == "p" && text_of(node).strip.empty? && node.xpath(".//w:drawing|.//w:pict|.//w:fldSimple", NS).empty?

      node.remove
    end
  end

  # Renames a font in every Word XML part (document, styles, numbering, fontTable, headers).
  # Applied when the package is written, after all other edits.
  def replace_font(from, to)
    (@font_renames ||= []) << [ from, to ]
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
    Array(@font_renames).each do |from, to|
      @entries.each_key do |name|
        next unless name.start_with?("word/") && name.end_with?(".xml")

        @entries[name] = @entries[name].dup.force_encoding("UTF-8").gsub(from, to)
      end
    end
    File.binwrite(@target, Zip::OutputStream.write_buffer do |zip|
      @entries.each do |name, bytes|
        zip.put_next_entry(name)
        zip.write(bytes)
      end
    end.string)
  end
end
