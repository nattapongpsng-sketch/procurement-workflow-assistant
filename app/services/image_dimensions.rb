# Reads pixel width/height from PNG or JPEG bytes without image libraries.
module ImageDimensions
  PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b
  JPEG_SOF = [ 0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF ].freeze

  module_function

  # => [width, height] or nil when the format is not recognised.
  def call(bytes)
    bytes = bytes.b
    return bytes.byteslice(16, 8).unpack("NN") if bytes.start_with?(PNG_SIGNATURE)
    return jpeg(bytes) if bytes.start_with?("\xFF\xD8".b)

    nil
  end

  # Scales to fit inside max_w × max_h (cm) keeping the aspect ratio.
  def fit_cm(bytes, max_w:, max_h:)
    width, height = call(bytes)
    return nil unless width&.positive? && height&.positive?

    scale = [ max_w / width.to_f, max_h / height.to_f ].min
    { width: "#{(width * scale).round(2)}cm", height: "#{(height * scale).round(2)}cm" }
  end

  def jpeg(bytes)
    offset = 2
    while offset < bytes.bytesize
      offset += 1 while bytes.getbyte(offset) == 0xFF && bytes.getbyte(offset + 1) == 0xFF
      marker = bytes.getbyte(offset + 1)
      length = bytes.byteslice(offset + 2, 2).unpack1("n")
      return bytes.byteslice(offset + 5, 4).unpack("nn").reverse if JPEG_SOF.include?(marker)

      offset += 2 + length
    end
    nil
  end
end
