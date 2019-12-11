#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'ssdp'
require 'eventmachine'
require 'ansi_server'

STDOUT.sync = true


# TODO: args
SCROLL_DELAY = 300

def boot_ssdp_server
  producer = SSDP::Producer.new(notifier: true)
  producer.add_service('ansi', 'AL': 'lol', 'LOCATION': 'server')
  producer.start
end

# TODO: is this used?
def boot_ansi_server
  Thread.new do
    EventMachine.run do
      Signal.trap('INT') { EventMachine.stop }
      Signal.trap('TERM') { EventMachine.stop }
      EventMachine.start_server('0.0.0.0', 1337, AnsiServer)
    end
  end
end

# TODO: move this into lib
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

  def initialize
    @offset = 0
    read_file
  end

  def advance
    @offset += 1
    @offset = 0 if @offset * ART_WIDTH * 2 > @ansi_file_size
  end

  def read_file
    # TODO: file as arg
    ansi_file = File.open('blocktronics_acid_trip.bin', 'rb')
    ansi_bytes = ansi_file.read
    ansi_file.close
    @ansi_file_size = ansi_bytes.size
    @ansi_lines = @ansi_file_size / (ART_WIDTH * 2)

    puts "#{@ansi_lines} lines"

    @characters = ansi_bytes.chars.select.with_index { |_, i| i.even? }.join.force_encoding('IBM437')
    @color_codes = ansi_bytes.bytes.select.with_index { |_, i| i.odd? }
  end

  def build_line(lcd_number)
    (0...ART_WIDTH).map do |c|
      line_offset = @offset - ART_HEIGHT * lcd_number
      if line_offset < 0
        line_offset = @ansi_lines + line_offset
      end
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

puts 'Booting server'
boot_ssdp_server

EventMachine.run do
  out_q = EventMachine::Queue.new
  reader = AnsiReader.new
  EventMachine.start_server('0.0.0.0', 1337, AnsiServer, out_q, reader)

  EventMachine::PeriodicTimer.new(0.3) do
    # TODO: do I still need queues?
    out_q.push(true)
    reader.advance
  end
end
