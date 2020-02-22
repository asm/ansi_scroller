#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'ssdp'
require 'eventmachine'
require 'ansi_server'
require 'ansi_reader'

STDOUT.sync = true


# TODO: args
SCROLL_DELAY = 300

def boot_ssdp_server
  producer = SSDP::Producer.new(notifier: true)
  producer.add_service('ansi', 'AL': 'lol', 'LOCATION': 'server')
  producer.start
end

puts 'Booting server'
boot_ssdp_server

EventMachine.run do
  reader = AnsiReader.new('blocktronics_acid_trip.bin')
  EventMachine.start_server('0.0.0.0', 1337, AnsiServer, reader)

  EventMachine::PeriodicTimer.new(0.3) do
    AnsiServer.tick
    reader.advance
  end
end
