# Thai-language helpers used by documents and the UI.
# Values that can be computed (amounts in words, Buddhist Era dates) must come
# from here, never from user input (design principle 3).
module Thai
  module_function

  def baht_text(amount) = Thai::BahtText.call(amount)

  def money(amount) = Thai::Money.format(amount)

  def date(value, format: :full) = Thai::DateFormat.call(value, format:)

  def buddhist_year(value) = Thai::DateFormat.buddhist_year(value)

  def doc_number(unit_code, number, year) = Thai::DocNumber.call(unit_code, number, year)

  # Parses Integer/BigDecimal/numeric String into BigDecimal; raises on anything else.
  def decimal(amount)
    raise ArgumentError, "amount is required" if amount.nil?
    return amount if amount.is_a?(BigDecimal)
    return BigDecimal(amount) if amount.is_a?(Integer)

    BigDecimal(amount.to_s.delete(","))
  rescue ArgumentError, TypeError
    raise ArgumentError, "not a number: #{amount.inspect}"
  end
end
