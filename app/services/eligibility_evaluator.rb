# Evaluates a workflow's declarative eligibility rules against case values.
# A failing rule always explains why and points to alternatives (design principle 4).
#
#   - id: max_50k
#     title: วงเงินไม่เกิน 50,000 บาท
#     check: { lte: [budget.total, 50000] }
#     fail: { reason: "...", alternatives: [ai_purchase_over_50k] }
#
# Operators: lte gte lt gt eq (two operands: field key or number), present (key),
# in_reference ({ field:, table: }), all / any (list of checks).
class EligibilityEvaluator
  COMPARISONS = { "lte" => :<=, "gte" => :>=, "lt" => :<, "gt" => :>, "eq" => :== }.freeze
  OPERATORS = COMPARISONS.keys + %w[present in_reference all any]

  Result = Data.define(:rule_id, :title, :status, :message, :alternatives) do
    def passed? = status == :pass
    def failed? = status == :fail
    def unknown? = status == :unknown
  end

  Outcome = Data.define(:results) do
    def eligible? = results.all?(&:passed?)
    def failures = results.select(&:failed?)
    def unknowns = results.select(&:unknown?)
    def alternatives = failures.flat_map(&:alternatives).uniq
  end

  def self.rule_problems(rule)
    return [ "ต้องเป็น object" ] unless rule.is_a?(Hash)

    rule = rule.deep_stringify_keys
    problems = []
    problems << "ต้องมี id" if rule["id"].blank?
    problems << "ต้องมี title" if rule["title"].blank?
    problems << "ต้องมี fail.reason (บอกเหตุผลเมื่อไม่ผ่าน)" if rule.dig("fail", "reason").blank?
    problems.concat(check_problems(rule["check"]))
  end

  def self.check_problems(check)
    return [ "check ต้องมีตัวดำเนินการ 1 ตัว" ] unless check.is_a?(Hash) && check.size == 1

    operator, operand = check.first
    case operator.to_s
    when *COMPARISONS.keys then operand.is_a?(Array) && operand.size == 2 ? [] : [ "#{operator} ต้องมี 2 ค่า" ]
    when "present" then operand.is_a?(String) ? [] : [ "present ต้องระบุ key" ]
    when "in_reference"
      operand.is_a?(Hash) && ReferenceTables.known?(operand.stringify_keys["table"]) ? [] : [ "in_reference ต้องมี field และ table ที่รู้จัก" ]
    when "all", "any"
      operand.is_a?(Array) && operand.any? ? operand.flat_map { |c| check_problems(c) } : [ "#{operator} ต้องเป็นรายการ" ]
    else [ "ไม่รู้จักตัวดำเนินการ #{operator}" ]
    end
  end

  def initialize(workflow_template, data)
    @rules = workflow_template.eligibility_rules.map(&:deep_stringify_keys)
    @computer = FieldComputer.new(workflow_template, data)
  end

  def call
    Outcome.new(results: @rules.map { |rule| evaluate_rule(rule) })
  end

  private

  def evaluate_rule(rule)
    status = case check(rule["check"])
    when true then :pass
    when false then :fail
    else :unknown
    end
    message = case status
    when :pass then rule.dig("pass", "message") || rule["title"]
    when :fail then rule.dig("fail", "reason")
    else rule["unknown_message"] || "ยังตรวจไม่ได้ เพราะยังไม่ได้กรอกข้อมูลที่ต้องใช้"
    end
    alternatives = status == :fail ? Array(rule.dig("fail", "alternatives")) : []
    Result.new(rule_id: rule["id"], title: rule["title"], status:, message:, alternatives:)
  end

  # Returns true, false, or nil when required data is missing.
  def check(node)
    operator, operand = node.first
    case operator
    when *COMPARISONS.keys then compare(COMPARISONS[operator], *operand)
    when "present" then @computer.value(operand).present?
    when "in_reference" then in_reference(operand)
    when "all" then combine(operand.map { |c| check(c) }, :all?)
    when "any" then combine(operand.map { |c| check(c) }, :any?)
    end
  end

  def compare(operator, left, right)
    a = operand_value(left)
    b = operand_value(right)
    return nil if a.nil? || b.nil?

    a.public_send(operator, b)
  end

  def operand_value(operand)
    operand.is_a?(Numeric) ? BigDecimal(operand.to_s) : @computer.value(operand)
  end

  def in_reference(operand)
    operand = operand.stringify_keys
    id = @computer.value(operand["field"])
    return nil if id.blank?

    ReferenceTables.scope(operand["table"]).exists?(id:)
  end

  def combine(results, method)
    return false if method == :all? && results.include?(false)
    return true if method == :any? && results.include?(true)
    return nil if results.include?(nil)

    results.public_send(method)
  end
end
