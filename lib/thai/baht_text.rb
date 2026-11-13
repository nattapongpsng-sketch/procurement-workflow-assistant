module Thai
  # Converts an amount of money to Thai words, e.g. 7990 => "เจ็ดพันเก้าร้อยเก้าสิบบาทถ้วน".
  module BahtText
    DIGITS = %w[ศูนย์ หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด เก้า].freeze
    PLACES = [ "", "สิบ", "ร้อย", "พัน", "หมื่น", "แสน" ].freeze

    module_function

    def call(amount)
      value = Thai.decimal(amount).round(2)
      raise ArgumentError, "amount must not be negative" if value.negative?

      baht = value.to_i
      satang = ((value - baht) * 100).to_i

      return "#{number_words(satang)}สตางค์" if baht.zero? && satang.positive?

      text = "#{baht.zero? ? DIGITS[0] : number_words(baht)}บาท"
      satang.zero? ? "#{text}ถ้วน" : "#{text}#{number_words(satang)}สตางค์"
    end

    # Reads a positive integer. Groups of six digits are joined with "ล้าน".
    def number_words(number)
      millions, rest = number.divmod(1_000_000)
      head = millions.positive? ? "#{number_words(millions)}ล้าน" : ""
      head + group_words(rest, has_higher: millions.positive?)
    end

    def group_words(number, has_higher:)
      digits = number.digits # least significant first
      digits.each_with_index.reverse_each.map do |digit, place|
        next "" if digit.zero?

        word_for(digit, place, more_significant: has_higher || digits[(place + 1)..].any?(&:positive?))
      end.join
    end

    def word_for(digit, place, more_significant:)
      case [ place, digit ]
      in [ 0, 1 ] then more_significant ? "เอ็ด" : DIGITS[1]
      in [ 1, 1 ] then PLACES[1]
      in [ 1, 2 ] then "ยี่#{PLACES[1]}"
      else "#{DIGITS[digit]}#{PLACES[place]}"
      end
    end
  end
end
