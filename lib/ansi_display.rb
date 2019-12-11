require 'sdl2'

ART_WIDTH    = 80
ART_HEIGHT   = 30
CHAR_WIDTH   = 8
CHAR_HEIGHT  = 20

SURFACE_WIDTH = CHAR_WIDTH * ART_WIDTH
SURFACE_HEIGHT = CHAR_HEIGHT * ART_HEIGHT

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

class AnsiDisplay
  def initialize(in_q: nil, out_q: nil)
    #@offset = ART_HEIGHT

    @in_q = in_q
    @out_q = out_q

    return unless in_q

    cb = proc do |msg|
      #@offset = msg - ART_HEIGHT * LCD_NUMBER
      @in_q.pop(&cb)
      render_line(msg)
    end

    @in_q.pop(&cb)
  end

  def render_init
    # TODO: file as arg
    #ansi_file = File.open('blocktronics_acid_trip.bin', 'rb')
    #ansi_bytes = ansi_file.read
    #ansi_file.close
    #@ansi_file_size = ansi_bytes.size

    #@characters = ansi_bytes.chars.select.with_index { |_, i| i.even? }.join.force_encoding('IBM437')
    #@color_codes = ansi_bytes.bytes.select.with_index { |_, i| i.odd? }

    SDL2.init(SDL2::INIT_VIDEO)
    SDL2::TTF.init

    SDL2::Mouse::Cursor.hide

    window = SDL2::Window.create('lol art',
                                 SDL2::Window::POS_CENTERED, SDL2::Window::POS_CENTERED,
                                 800, 600, 0)
    @renderer = window.create_renderer(-1, 0)

    @font = SDL2::TTF.open('Px437_IBM_VGA9.ttf', CHAR_HEIGHT)

    @surface = SDL2::Surface.new(SURFACE_WIDTH, SURFACE_HEIGHT, 32)

    # Fill the initial screen
    #for line in 0..ART_HEIGHT do
    #  row_surface = render_row(line)
    #  SDL2::Surface.blit(row_surface, nil, @surface, SDL2::Rect.new(0, line * CHAR_HEIGHT, SURFACE_WIDTH, CHAR_HEIGHT))
    #  row_surface.destroy
    #end

    render_surface
    @renderer.present
  end

  def render_row(data)
    row_surface = SDL2::Surface.new(SURFACE_WIDTH, CHAR_HEIGHT, 32)
    for c, i in data.each_with_index do
      char = c[0]
      fg_color = c[1]
      bg_color = c[2]
      char_surface = @font.render_shaded(char, fg_color, bg_color)

      char_rect = SDL2::Rect.new(i * CHAR_WIDTH, 0, CHAR_WIDTH, CHAR_HEIGHT)
      SDL2::Surface.blit(char_surface, nil, row_surface, char_rect)
      char_surface.destroy
    end

    row_surface
  end

  # TODO: remove me
  def render_row_offset(offset)
    row_surface = SDL2::Surface.new(SURFACE_WIDTH, CHAR_HEIGHT, 32)
    for c in 0...ART_WIDTH do
      idx = offset * ART_WIDTH + c

      # We've hit the sauce info
      break if @characters[idx] == "\x1a"

      color = @color_codes[idx]
      fg_color = color & 0b1111
      bg_color = color >> 4

      char_surface = @font.render_shaded(@characters[idx], COLOR_MAP[fg_color], COLOR_MAP[bg_color])
      char_rect = SDL2::Rect.new(c * CHAR_WIDTH, 0, CHAR_WIDTH, CHAR_HEIGHT)
      SDL2::Surface.blit(char_surface, nil, row_surface, char_rect)
      char_surface.destroy
    end

    row_surface
  end

  # Copy the working surface to the renderer
  def render_surface
    texture = @renderer.create_texture_from(@surface)
    @renderer.copy(texture, nil, nil)
    texture.destroy
  end

  # TODO: remove me
  def advance
    @offset += 1
    @offset = 0 if @offset * ART_WIDTH * 2 > @ansi_file_size
    @out_q&.push(@offset)
  end

  # Renders a line at the bottom
  def render_line(data)
    # Shift down a line
    SDL2::Surface.blit(@surface, SDL2::Rect.new(0, CHAR_HEIGHT, SURFACE_WIDTH, SURFACE_HEIGHT - CHAR_HEIGHT), @surface, nil)

    # Blit the next line and render
    row_surface = render_row(data)
    SDL2::Surface.blit(row_surface , nil, @surface, SDL2::Rect.new(0, CHAR_HEIGHT * (ART_HEIGHT-1), SURFACE_WIDTH, CHAR_HEIGHT))
    row_surface.destroy
    render_surface
    @renderer.present
  end
end
