module Thai
  # Thai dates in Buddhist Era: "17 กรกฎาคม 2569" (full) or "17 ก.ค. 2569" (short).
  module DateFormat
    FULL_MONTHS = %w[มกราคม กุมภาพันธ์ มีนาคม เมษายน พฤษภาคม มิถุนายน
                     กรกฎาคม สิงหาคม กันยายน ตุลาคม พฤศจิกายน ธันวาคม].freeze
    SHORT_MONTHS = %w[ม.ค. ก.พ. มี.ค. เม.ย. พ.ค. มิ.ย. ก.ค. ส.ค. ก.ย. ต.ค. พ.ย. ธ.ค.].freeze
    BE_OFFSET = 543

    module_function

    def call(value, format: :full)
      date = to_date(value)
      return nil if date.nil?

      months = format == :short ? SHORT_MONTHS : FULL_MONTHS
      "#{date.day} #{months[date.month - 1]} #{date.year + BE_OFFSET}"
    end

    def buddhist_year(value)
      to_date(value)&.then { |date| date.year + BE_OFFSET }
    end

    def to_date(value)
      case value
      when nil, "" then nil
      when Date then value
      when Time, ActiveSupport::TimeWithZone, DateTime then value.to_date
      else Date.iso8601(value.to_s)
      end
    end
  end
end
