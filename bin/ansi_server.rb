#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'ssdp'
require 'eventmachine'
require 'net/http'
require 'json'

require 'ansi_server'
require 'ansi_reader'
require 'url_carousel'

STDOUT.sync = true

# TODO: args?

puts 'Booting server'
producer = SSDP::Producer.new(notifier: true)
producer.add_service('ansi', 'AL': 'lol', 'LOCATION': 'server')
producer.start

carousel = UrlCarousel.new('http://asm.dj/ansi/index.json')

EventMachine.run do
  EventMachine.start_server('0.0.0.0', 1337, AnsiServer, carousel)

  EventMachine::PeriodicTimer.new(0.3) do
    AnsiServer.tick
    carousel.reader.advance
  end

  EventMachine::PeriodicTimer.new(600) do
    carousel.next
  end
end
