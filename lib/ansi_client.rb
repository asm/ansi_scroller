require 'eventmachine'
require 'json'

class AnsiClient < EM::Connection
  def initialize(q, screen_idx)
    @queue = q
    @screen_idx = screen_idx
  end

  def receive_data(data)
    line = JSON.parse(data)
    return unless line

    @queue.push(line)
  rescue JSON::ParserError
    puts 'Failed to parse JSON'
  end

  def post_init
    send_data(@screen_idx)
  end
end