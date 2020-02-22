#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'ssdp'
require 'eventmachine'
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

def boot_client
  server_ip = nil

  while server_ip.nil?
    puts 'Searching for server...'
    finder = SSDP::Consumer.new(timeout: 3)
    results = finder.search(service: 'ansi')

    next unless results

    results.each do |result|
      server_ip = result[:address] if result[:params]['LOCATION'] == 'server'
    end
  end

  puts "Found server at #{server_ip}"

  EventMachine.run do
    in_q = EventMachine::Queue.new
    EventMachine.connect(server_ip, 1337, AnsiClient, in_q, LCD_NUMBER)

    ansi_display = AnsiDisplay.new(in_q: in_q)
    ansi_display.render_init
  end
end

puts 'Booting client'
boot_client
