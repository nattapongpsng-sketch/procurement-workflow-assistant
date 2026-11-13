# Reference data that workflow definitions may point at by name.
module ReferenceTables
  TABLES = {
    "recommended_ai" => -> { RecommendedAi.active },
    "person" => -> { Person.all },
    "budget_source" => -> { BudgetSource.all }
  }.freeze

  module_function

  def names = TABLES.keys

  def known?(name) = TABLES.key?(name.to_s)

  def scope(name)
    TABLES.fetch(name.to_s) { raise ArgumentError, "unknown reference table: #{name}" }.call
  end

  def find(name, id)
    return nil if id.blank?

    scope(name).find_by(id:)
  end
end
