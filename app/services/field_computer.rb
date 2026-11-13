# Resolves every field value of a case: casts stored inputs and derives computed
# fields from a whitelist of named functions (no eval). Design principle 3.
#
#   computed: { fn: multiply, args: [price.unit_price, item.quantity] }
#
# An arg is a field key, or { value: <literal> } for a constant.
class FieldComputer
  class CycleError < StandardError; end

  FUNCTIONS = {
    "multiply" => ->(*nums) { nums.inject { |product, n| product * n } },
    "sum" => ->(*nums) { nums.sum },
    "baht_text" => ->(amount) { Thai.baht_text(amount) },
    "money" => ->(amount) { Thai.money(amount) },
    "thai_date" => ->(date) { Thai.date(date) },
    "thai_date_short" => ->(date) { Thai.date(date, format: :short) },
    "buddhist_year" => ->(date) { Thai.buddhist_year(date) },
    # Year of the letter, or the current year while the letter is undated.
    "buddhist_year_or_current" => ->(date) { Thai.buddhist_year(date.presence || Date.current) },
    "doc_number" => ->(unit_code, number, year) { Thai.doc_number(unit_code, number, year) },
    "concat" => ->(*parts) { parts.map { |part| FieldComputer.text(part) }.join },
    "first_present" => ->(*values) { values.find(&:present?) }
  }.freeze

  # Functions that accept blank args (others return nil if any arg is blank).
  BLANK_TOLERANT = %w[buddhist_year_or_current doc_number first_present].freeze

  # Plain-text rendering of a value inside generated sentences.
  def self.text(value)
    case value
    when BigDecimal then value.frac.zero? ? value.to_i.to_fs(:delimited) : value.to_s("F")
    when Date then Thai.date(value)
    else value.to_s
    end
  end

  def self.formula_problems(computed)
    return [ "ต้องเป็น object ที่มี fn และ args" ] unless computed.is_a?(Hash)

    fn = computed["fn"] || computed[:fn]
    args = computed["args"] || computed[:args]
    problems = []
    problems << "ไม่รู้จักฟังก์ชัน #{fn.inspect}" unless FUNCTIONS.key?(fn.to_s)
    problems << "args ต้องเป็นรายการ" unless args.is_a?(Array)
    problems
  end

  def initialize(workflow_template, data)
    @definitions = workflow_template.field_definitions.index_by(&:key)
    @data = data.to_h.stringify_keys
    @cache = {}
  end

  # Every defined key => resolved value (Ruby objects: BigDecimal, Date, String, ...).
  def values
    @definitions.keys.index_with { |key| value(key) }
  end

  def value(key, visiting = [])
    key = key.to_s
    return @cache[key] if @cache.key?(key)
    raise CycleError, "วนซ้ำในสูตร: #{(visiting + [ key ]).join(' -> ')}" if visiting.include?(key)

    definition = @definitions[key]
    @cache[key] = if definition.nil? then nil
    elsif definition.computed? then compute(definition, visiting + [ key ])
    else cast(definition, @data[key])
    end
  end

  private

  def compute(definition, visiting)
    fn = definition.computed["fn"]
    raw_args = Array(definition.computed["args"])
    args = raw_args.map { |arg| resolve_arg(arg, visiting) }
    # Only field values count as missing; literals such as " " are kept as-is.
    missing = raw_args.zip(args).any? { |raw, value| !raw.is_a?(Hash) && value.blank? }
    return nil if missing && !BLANK_TOLERANT.include?(fn)

    FUNCTIONS.fetch(fn).call(*args)
  end

  def resolve_arg(arg, visiting)
    arg.is_a?(Hash) ? arg.stringify_keys["value"] : value(arg, visiting)
  end

  def cast(definition, raw)
    raw = definition.options["default"] if raw.nil? || raw == ""
    return nil if raw.nil? || raw == ""

    case definition.field_type
    when "money", "number" then Thai.decimal(raw)
    when "date" then Thai::DateFormat.to_date(raw)
    when "boolean" then ActiveModel::Type::Boolean.new.cast(raw)
    else raw
    end
  end
end
