#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'ssdp'
require 'eventmachine'
require 'ansi_server'
require 'ansi_client'
require 'ansi_display'

STDOUT.sync = true

LCD_NUMBER = ENV['LCD_NUMBER']&.to_i

if LCD_NUMBER
  puts "This is display number #{LCD_NUMBER}"
else
  puts 'No LCD number!'
  exit
end

def boot_ssdp_server
  producer = SSDP::Producer.new(notifier: true)
  producer.add_service('ansi', 'AL': 'lol', 'LOCATION': LCD_NUMBER)
  producer.start
end

def boot_ansi_server
  Thread.new do
    EventMachine.run do
      Signal.trap('INT') { EventMachine.stop }
      Signal.trap('TERM') { EventMachine.stop }
      EventMachine.start_server('0.0.0.0', 1337, AnsiServer)
    end
  end
end

def boot_tail
  lcds = {}
  loop do
    puts 'Searching for head LCD...'
    finder = SSDP::Consumer.new(timeout: 3)
    results = finder.search(service: 'ansi')

    # TODO: clean this up
    if results
      results.each do |result|
        puts "Found lcd number #{result[:params]['LOCATION']}"
        lcds[result[:params]['LOCATION'].to_i] = result[:address]
      end
    else
      puts 'no result'
    end

    break if lcds[0]
  end

  puts "Connecting to head LCD at #{lcds[0]}"
  EventMachine.run do
    in_q = EventMachine::Queue.new
    EventMachine.connect(lcds[0], 1337, AnsiClient, in_q)

    ansi_display = AnsiDisplay.new(in_q: in_q)
    ansi_display.render_init
  end
end

if LCD_NUMBER.zero?
  puts 'Booting head'

  boot_ssdp_server

  EventMachine.run do
    out_q = EventMachine::Queue.new
    EventMachine.start_server('0.0.0.0', 1337, AnsiServer, out_q)

    ansi_display = AnsiDisplay.new(out_q: out_q)
    ansi_display.render_init

    EventMachine::PeriodicTimer.new(0.3) do
      ansi_display.render_line
      ansi_display.advance
    end
  end
else
  puts 'Booting tail'
  boot_tail
end
