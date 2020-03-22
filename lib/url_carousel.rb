class UrlCarousel
  attr_reader :reader

  def initialize(url_list)
    uri = URI(url_list)
    response = Net::HTTP.get(uri)
    @ansi_urls = JSON.parse(response)
    @url_idx = 0
    load_ansi
  end

  def next
    @url_idx = (@url_idx + 1) % @ansi_urls.size
    load_ansi
  end

  def load_ansi
    uri = URI(@ansi_urls[@url_idx])
    bytes = Net::HTTP.get(uri)
    @reader = AnsiReader.new(bytes: bytes)
  end

  def build_line(lcd_number)
    @reader.build_line(lcd_number)
  end
end
