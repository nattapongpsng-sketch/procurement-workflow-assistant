# Finds workflows for a free-text query such as "ซื้อ AI" or "license ซอฟต์แวร์".
# Thai has no spaces between words and SQLite FTS5 cannot segment it, so M0
# scores substring matches in Ruby over the latest published versions.
class WorkflowSearch
  WEIGHTS = { keyword: 4, name: 3, description: 1 }.freeze

  Result = Data.define(:workflow, :score, :matched_terms)

  def self.call(query) = new(query).call

  def initialize(query)
    @query = normalize(query)
    @tokens = @query.split(/\s+/).reject(&:empty?)
  end

  def call
    workflows = WorkflowTemplate.latest_published.order(:name).to_a
    return workflows.map { |w| Result.new(workflow: w, score: 0, matched_terms: []) } if @tokens.empty?

    workflows.filter_map { |workflow| score(workflow) }.sort_by { |result| [ -result.score, result.workflow.name ] }
  end

  private

  def score(workflow)
    matched = []
    total = 0

    workflow.keywords.each do |keyword|
      key = normalize(keyword)
      next unless @tokens.any? { |token| key.include?(token) || token.include?(key) } || @query.include?(key)

      matched << keyword
      total += WEIGHTS[:keyword]
    end
    total += WEIGHTS[:name] * @tokens.count { |token| normalize(workflow.name).include?(token) }
    total += WEIGHTS[:description] * @tokens.count { |token| normalize(workflow.description).include?(token) }

    Result.new(workflow:, score: total, matched_terms: matched.uniq) if total.positive?
  end

  def normalize(text) = text.to_s.unicode_normalize(:nfc).downcase.strip
end
