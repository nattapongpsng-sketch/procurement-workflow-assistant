module Thai
  # Formats money the way PEA memos do: whole baht end with ".-" (7,990.-),
  # amounts with satang keep two decimals (7,990.50).
  module Money
    module_function

    def format(amount)
      value = Thai.decimal(amount).round(2)
      baht = value.truncate
      grouped = baht.to_i.abs.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
      grouped = "-#{grouped}" if value.negative?
      return "#{grouped}.-" if value == baht

      satang = ((value - baht).abs * 100).round.to_i
      "#{grouped}.#{satang.to_s.rjust(2, '0')}"
    end
  end
end
