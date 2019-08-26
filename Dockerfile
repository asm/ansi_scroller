FROM raspbian/stretch

RUN apt-get update && apt-get install -y ruby ruby-dev libfontconfig-dev automake libtool \ 
  libfreeimage-dev libopenal-dev libpango1.0-dev libudev-dev libtiff5-dev libwebp-dev \
  freeglut3-dev libjpeg-dev wget libraspberrypi-dev

WORKDIR /tmp
RUN wget https://www.libsdl.org/release/SDL2-2.0.10.tar.gz
RUN wget http://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.14.tar.gz

RUN tar zxf SDL2-2.0.10.tar.gz
RUN tar zxf SDL2_ttf-2.0.14.tar.gz

RUN cd SDL2-2.0.10 && ./configure --disable-pulseaudio --disable-esd \
  --disable-video-wayland --disable-video-opengl --host=arm-raspberry-linux-gnueabihf \
  --prefix=/usr && make && sudo make install

RUN cd SDL2_ttf-2.0.14  && ./configure --prefix=/usr && make && sudo make install

RUN gem install --no-ri --no-rdoc ruby-sdl2 ssdp eventmachine

RUN mkdir -p /opt/ansi_scroller
COPY ansi_scroller.rb *.bin *.ttf /opt/ansi_scroller/

WORKDIR /opt/ansi_scroller

ARG LCD_NUMBER=0
ENV LCD_NUMBER=$LCD_NUMBER
CMD ["ruby", "ansi_scroller.rb"]
