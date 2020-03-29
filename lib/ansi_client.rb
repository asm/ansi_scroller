require 'eventmachine'
require 'json'
require 'socket'

class AnsiClient < EM::Connection
  include EM::P::ObjectProtocol

  def initialize(queue, screen_idx)
    @queue = queue
    @screen_idx = screen_idx
  end

  def receive_object(line)
    return unless line

    @queue.push(line)
  end

  def post_init
    @server_port, @server_ip = Socket.unpack_sockaddr_in(get_peername)
    puts "Connected to server at #{@server_ip}:#{@server_port}"
    send_data(@screen_idx)
  end

  def unbind
    puts 'Unbind called, exiting.'
    exit
  end
end
