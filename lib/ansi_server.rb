require 'eventmachine'
require 'json'

class AnsiServer < EM::Connection
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
        @@screens.delete(self)
      end
    end
  end

  def send_line
    return unless @screen_idx

    send_data(@reader.build_line(@screen_idx).to_json + "\n")
  end

  def post_init
    @@screens << self
  end

  def unbind
    @@screens.delete(self)
  end
end
