FROM ubuntu:18.04

RUN apt-get update && apt-get install -y ruby ruby-dev libsdl2-dev libsdl2-ttf-dev
RUN gem install ruby-sdl2 pry ssdp eventmachine

RUN mkdir -p /opt/ansi_scroller
COPY foo2.rb *.bin *.ttf /opt/ansi_scroller/

WORKDIR /opt/ansi_scroller

CMD ["ruby", "foo2.rb"]
