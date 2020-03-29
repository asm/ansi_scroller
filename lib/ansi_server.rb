require 'eventmachine'
require 'json'

class AnsiServer < EM::Connection
  include EM::P::ObjectProtocol
  @@screens = []

  def initialize(reader)
    @reader = reader
  end

  def receive_data(data)
    @screen_idx = data.to_i
    puts "Screen #{@screen_idx} connected"
  end

  def self.tick
    @@screens.each do |screen|
      begin
        screen.send_line
      rescue => e
        puts e
        screen.close_connection
        @@screens.delete(screen)
      end
    end
  end

  def send_line
    return unless @screen_idx

    send_object(@reader.build_line(@screen_idx))
  end

  def post_init
    @@screens << self
  end

  def unbind
    @@screens.delete(self)
  end
end
