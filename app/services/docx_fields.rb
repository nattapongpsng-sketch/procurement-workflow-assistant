require "zip"

# Lists the Sablon MERGEFIELD expressions used in a .docx template.
module DocxFields
  PARTS = %r{\Aword/(document|header\d*|footer\d*)\.xml\z}
  INSTR = /MERGEFIELD\s+(\S+)\s+\\\*\s+MERGEFORMAT/

  module_function

  # => ["=org.unit_name", "price.evidence:if", "@price.evidence:start", ...]
  def expressions(path)
    Zip::File.open(path.to_s) do |zip|
      zip.entries.select { |entry| entry.name.match?(PARTS) }
         .flat_map { |entry| entry.get_input_stream.read.force_encoding("UTF-8").scan(INSTR).flatten }
    end
  end

  # Data paths a template reads, e.g. "org.unit_name", "budget.source.ref_doc_no", "price.evidence".
  def paths(path)
    expressions(path).map { |expr| expr.delete_prefix("=").delete_prefix("@").sub(/:\w+\z/, "") }.uniq
  end
end
