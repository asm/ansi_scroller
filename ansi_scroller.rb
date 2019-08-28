#!/usr/bin/env ruby

require 'sdl2'
require 'ssdp'
require 'eventmachine'

STDOUT.sync = true

COLOR_MAP = {
  0 =>  [0, 0, 0],
  1 =>  [0, 0, 0xAB],
  2 =>  [0, 0xAB, 0],
  3 =>  [0, 0xAB, 0xAB],
  4 =>  [0xAB, 0, 0],
  5 =>  [0xAB, 0, 0xAB],
  6 =>  [0xAB, 0x57, 0],
  7 =>  [0xAB, 0xAB, 0xAB],
  8 =>  [0x57, 0x57, 0x57],
  9 =>  [0x57, 0x57, 0xFF],
  10 => [0x57, 0xFF, 0x57],
  11 => [0x57, 0xFF, 0xFF],
  12 => [0xFF, 0x57, 0x57],
  13 => [0xFF, 0x57, 0xFF],
  14 => [0xFF, 0xFF, 0x57],
  15 => [0xFF, 0xFF, 0xFF],
}

SCROLL_DELAY = 300
ART_WIDTH    = 80
ART_HEIGHT   = 30
CHAR_WIDTH   = 8
CHAR_HEIGHT  = 20

SURFACE_WIDTH = CHAR_WIDTH * ART_WIDTH
SURFACE_HEIGHT = CHAR_HEIGHT * ART_HEIGHT

LCD_NUMBER = ENV['LCD_NUMBER'] && ENV['LCD_NUMBER'].to_i

if LCD_NUMBER
  puts "This is display number #{LCD_NUMBER}"
else
  puts 'No LCD number!'
  exit
end

def boot_ssdp_server
  producer = SSDP::Producer.new(notifier: true)
  producer.add_service('ansi', {'AL': 'lol', 'LOCATION': LCD_NUMBER})
  producer.start
end

class AnsiServer < EM::Connection
  @@screens = []

  def initialize(q)
    @queue = q

    cb = Proc.new do |msg|
      @@screens.each do |screen|
        begin
          screen.send_data(msg.to_s + ',')
        rescue
          @screens.delete(self)
        end
      end
      q.pop &cb
    end

    q.pop &cb
  end

  def post_init
    @@screens << self
  end

  def unbind
    @@screens.delete(self)
  end
end

class AnsiClient < EM::Connection
  def initialize(q)
    @queue = q
  end

  def receive_data(data)
    @queue.push(data.split(',').last.to_i)
  end
end

def boot_ansi_server
  Thread.new do
    EventMachine.run do
      Signal.trap('INT') { EventMachine.stop }
      Signal.trap('TERM') { EventMachine.stop }
      EventMachine.start_server("0.0.0.0", 1337, AnsiServer)
    end
  end
end


class AnsiDisplay
  def initialize(in_q: nil, out_q: nil)
    @offset = ART_HEIGHT

    @in_q = in_q
    @out_q = out_q

    if in_q
      cb = Proc.new do |msg|
        @offset = msg + ART_HEIGHT + ART_HEIGHT * (LCD_NUMBER)
        @in_q.pop &cb
        render_line
      end

      @in_q.pop &cb
    end
  end

  def render_init
    ansi_file = File.open('blocktronics_acid_trip.bin', 'rb')
    ansi_bytes = ansi_file.read
    ansi_file.close
    @ansi_file_size = ansi_bytes.size


    @characters = ansi_bytes.chars.select.with_index { |_, i| i.even? }.join.force_encoding('IBM437')
    @color_codes = ansi_bytes.bytes.select.with_index { |_, i| i.odd? }

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
    for line in 0..ART_HEIGHT do
      row_surface = render_row(line)
      SDL2::Surface.blit(row_surface, nil, @surface, SDL2::Rect.new(0, line * CHAR_HEIGHT, SURFACE_WIDTH, CHAR_HEIGHT))
      row_surface.destroy
    end

    render_surface
    @renderer.present
  end

  def render_row(offset)
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

    return row_surface
  end

  # Copy the working surface to the renderer
  def render_surface
    texture = @renderer.create_texture_from(@surface)
    @renderer.copy(texture, nil, nil)
    texture.destroy
  end

  def advance
    @offset += 1
    @offset = 0 if @offset * ART_WIDTH * 2 > @ansi_file_size
  end

  # Renders a line at the bottom
  def render_line
    # Shift down a line
    SDL2::Surface.blit(@surface, SDL2::Rect.new(0, CHAR_HEIGHT, SURFACE_WIDTH, SURFACE_HEIGHT - CHAR_HEIGHT), @surface, nil)

    # Blit the next line and render
    row_surface = render_row(@offset)
    SDL2::Surface.blit(row_surface , nil, @surface, SDL2::Rect.new(0, CHAR_HEIGHT * (ART_HEIGHT-1), SURFACE_WIDTH, CHAR_HEIGHT))
    row_surface.destroy
    render_surface
    @out_q && @out_q.push(@offset - ART_HEIGHT)
    @renderer.present
  end
end

def boot_tail
  lcds = {}
  while true do
    puts 'Searching for head LCD...'
    finder = SSDP::Consumer.new(timeout: 3)
    results = finder.search(service: 'ansi')

    # TODO: clean this up
    if results
      for result in results do
        puts "Found lcd number #{result[:params]['LOCATION']}"
        lcds[result[:params]['LOCATION'].to_i] = result[:address]
      end
    else
      puts "no result"
    end

    if lcds[0]
      break
    end
  end

  puts "Connecting to head LCD at #{lcds[0]}"
  EventMachine.run do
    in_q = EventMachine::Queue.new
    EventMachine.connect(lcds[0], 1337, AnsiClient, in_q)

    ansi_display = AnsiDisplay.new(in_q: in_q)
    ansi_display.render_init
  end
end


if LCD_NUMBER == 0
  puts "Booting head"

  boot_ssdp_server

  EventMachine.run do
    out_q = EventMachine::Queue.new
    EventMachine.start_server("0.0.0.0", 1337, AnsiServer, out_q)

    ansi_display = AnsiDisplay.new(out_q: out_q)
    ansi_display.render_init

    EventMachine::PeriodicTimer.new(0.3) do
      ansi_display.render_line
      ansi_display.advance
    end
  end
else
  puts "Booting tail"
  boot_tail
end
