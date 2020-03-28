require 'eventmachine'
require 'json'

class AnsiClient < EM::Connection
  include EM::P::LineProtocol

  def initialize(queue, screen_idx)
    @queue = queue
    @screen_idx = screen_idx
  end

  def receive_line(data)
    line = JSON.parse(data)
    return unless line

    @queue.push(line)
  rescue JSON::ParserError
    puts 'Failed to parse JSON'
    reconnect(@options[:host], @options[:port])
  end

  def post_init
    send_data(@screen_idx)
  end
end
