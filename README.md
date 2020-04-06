# Raspberry Pi ANSI Scroller
Build a multi-monitor [ANSI Art](https://en.wikipedia.org/wiki/ANSI_art) scrolling display.  For example, here are 4 monitors connected to 4 Raspberry Pis:

![](http://asm.dj/ansi/art.jpg)

## Getting started:
On each Raspberry Pi, you'll need to run the following:

```bash
# This version of docker is the only one that seems to work on RPis at the moment
curl -fsSL https://get.docker.com | VERSION=18.06.3 sh
sudo apt install -y git
git clone git@github.com:asm/ansi_scroller.git
cd ansi_scroller

# On the server:
docker build -f Dockerfile.server . -t ansi_scroller_server
docker run --restart always --privileged --network host -dt ansi_scroller_server

# On all clients:
docker build -f Dockerfile.client . -t ansi_scroller_client
docker run --restart always --privileged --network host --env LCD_NUMBER -dt ansi_scroller_client
```
`--restart always` will run the Docker containers at boot, perfect for art installtions.  The clients will auto-discover the server via [SSDP](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol) so there's no config necessary as long as they're on the same network.  Running a client and server on the same node is supported.

## Loading your own art
The server loads a list of ANSI artworks to display from a JSON list via a URL.  You can change that URL [here](https://github.com/asm/ansi_scroller/blob/master/bin/ansi_server.rb#L23).  You'll note the files are in the `.bin` format (not `.ans`).  This format is far easier to read and you can use [PabloDraw](http://picoe.ca/products/pablodraw/) to convert artwork.  Someday, I'll write the code necessary to read `.ans` files.

## Development using Docker on linux
To ease development, there is a [Docker compose](https://github.com/asm/ansi_scroller/blob/master/docker-compose.yml) file that will run on Linux and Chrome OS.  It launches a server and four displays, each in its own window.

```bash
xhost +local:root
docker-compose up --build
```

## TODO
* Support `.ans` files.
* Better scrolling synchronization.

