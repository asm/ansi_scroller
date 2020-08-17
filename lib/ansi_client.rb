require 'eventmachine'
require 'json'
require 'socket'

class AnsiClient < EM::Connection
  include EM::P::ObjectProtocol

  def initialize(queue, screen_idx)
    @queue = queue
    @screen_idx = screen_idx
    set_comm_inactivity_timeout(1)
  end

  def receive_object(line)
    return unless line

    @queue.push(line)
  end

  def post_init
    send_data(@screen_idx)
  end

  def unbind
    puts 'Unbind called, exiting.'
    exit
  end
end
