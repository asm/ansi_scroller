require 'sdl2'

class AnsiDisplay
  ART_WIDTH    = 80
  ART_HEIGHT   = 30
  CHAR_WIDTH   = 8
  CHAR_HEIGHT  = 20

  SURFACE_WIDTH = CHAR_WIDTH * ART_WIDTH
  SURFACE_HEIGHT = CHAR_HEIGHT * ART_HEIGHT

  def initialize(in_q: nil)
    @in_q = in_q

    return unless in_q

    cb = proc do |msg|
      @in_q.pop(&cb)
      render_line(msg)
    end

    @in_q.pop(&cb)
  end

  def render_init
    SDL2.init(SDL2::INIT_VIDEO)
    SDL2::TTF.init

    SDL2::Mouse::Cursor.hide

    window = SDL2::Window.create('lol art',
                                 SDL2::Window::POS_CENTERED, SDL2::Window::POS_CENTERED,
                                 800, 600, 0)
    @renderer = window.create_renderer(-1, 0)

    @font = SDL2::TTF.open('Px437_IBM_VGA9.ttf', CHAR_HEIGHT)

    @surface = SDL2::Surface.new(SURFACE_WIDTH, SURFACE_HEIGHT, 32)

    render_surface
    @renderer.present
  end

  def render_row(data)
    row_surface = SDL2::Surface.new(SURFACE_WIDTH, CHAR_HEIGHT, 32)
    data.each_with_index do |c, i|
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

  # Copy the working surface to the renderer
  def render_surface
    texture = @renderer.create_texture_from(@surface)
    @renderer.copy(texture, nil, nil)
    texture.destroy
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
