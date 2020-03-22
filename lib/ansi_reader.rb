class AnsiReader
  ART_WIDTH  = 80
  ART_HEIGHT = 30

  COLOR_MAP = {
    0 => [0, 0, 0],
    1 => [0, 0, 0xAB],
    2 => [0, 0xAB, 0],
    3 => [0, 0xAB, 0xAB],
    4 => [0xAB, 0, 0],
    5 => [0xAB, 0, 0xAB],
    6 => [0xAB, 0x57, 0],
    7 => [0xAB, 0xAB, 0xAB],
    8 => [0x57, 0x57, 0x57],
    9 => [0x57, 0x57, 0xFF],
    10 => [0x57, 0xFF, 0x57],
    11 => [0x57, 0xFF, 0xFF],
    12 => [0xFF, 0x57, 0x57],
    13 => [0xFF, 0x57, 0xFF],
    14 => [0xFF, 0xFF, 0x57],
    15 => [0xFF, 0xFF, 0xFF],
  }.freeze

  def initialize(filename: nil, bytes: nil)
    @filename = filename
    @bytes = bytes
    @offset = 0

    read_file if @filename
    read_bytes if @bytes
  end

  def advance
    @offset += 1
    @offset = 0 if @offset * ART_WIDTH * 2 > @ansi_file_size
  end

  def read_file
    ansi_file = File.open(@filename, 'rb')
    @bytes = ansi_file.read
    ansi_file.close

    read_bytes
  end

  def read_bytes
    @ansi_file_size = @bytes.size
    @ansi_lines = @ansi_file_size / (ART_WIDTH * 2)

    @characters = @bytes.chars.select.with_index { |_, i| i.even? }.join.force_encoding('IBM437')
    @color_codes = @bytes.bytes.select.with_index { |_, i| i.odd? }
  end

  def build_line(lcd_number)
    (0...ART_WIDTH).map do |c|
      line_offset = @offset - ART_HEIGHT * lcd_number
      line_offset = @ansi_lines + line_offset if line_offset.negative?
      idx = line_offset * ART_WIDTH + c

      # We've hit the sauce info
      break if @characters[idx] == "\x1a"

      color = @color_codes[idx]
      fg_color = color & 0b1111
      bg_color = color >> 4

      [@characters[idx], COLOR_MAP[fg_color], COLOR_MAP[bg_color]]
    end
  end
end
