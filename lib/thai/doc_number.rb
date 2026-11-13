module Thai
  # Outgoing letter numbers: "สชก.(บก-ท) 617/2569".
  # The running number is issued only when the letter is registered, so a
  # missing number leaves a blank gap to be written in by hand.
  module DocNumber
    BLANK_GAP = " " * 9

    module_function

    def call(unit_code, number, year)
      return "#{unit_code}#{BLANK_GAP}/#{year}" if number.blank?

      "#{unit_code} #{number}/#{year}"
    end
  end
end
