# Raspberry Pi ANSI Scroller
Build a multi-monitor [ANSI Art](https://en.wikipedia.org/wiki/ANSI_art) scrolling display.  For example, here are 4 monitors connected to 4 Raspberry Pis:

![](http://asm.dj/ansi/art.jpg)

## Getting started:
On each Raspberry Pi, you'll need to run the following:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker pi
# Log out/log in again to pick up the new group

# On the server:
docker run --restart always --privileged --network host -dt ghcr.io/asm/ansi_scroller_server:latest

# On all clients:
# On older RPI models, you may have to switch to the legacy GL driver (use raspi-config, advanced options) if you see errors when launching the client
# Be sure to set the LCD_NUMBER to something between 0 (inclusive) and the number of screens - 1
# where LCD_NUMBER=0 is located at the bottom of the stack:
export LCD_NUMBER=xxx
docker run --restart always --privileged --network host --env LCD_NUMBER -dt ghcr.io/asm/ansi_scroller_client:latest
```
`--restart always` will run the Docker containers at boot, perfect for art installations.  The clients will auto-discover the server via [SSDP](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol) so there's no config necessary (other than setting the screen number) as long as they're on the same network.  Running a client and server on the same node is supported.  You might consider setting the screen number in `/etc/profile` to make it permanent.

### Scheduling Screen Power
You can power down/up your screens on a schedule using `cron` and `vcgencmd` (RPi only).  For example, to power down at 10pm and up again at 8am (be sure to check your timezone), simply run `crontab -e` and append:

```
0 22 * * * vcgencmd display_power 0
0 08 * * * vcgencmd display_power 1
```

### Running Everything on a Read-Only Filesystem
SD cards are notorious for corrupting filesystems, usually due to excessive or dirty writes (ie during power loss).  To prevent these issues, it's possible to run everything on [OverlayFS](https://en.wikipedia.org/wiki/OverlayFS).
```bash
sudo apt install -y fuse-overlayfs
# This will overwrite your docker config, be sure to check if this file exists
echo "{
  "storage-driver": "fuse-overlayfs"
}" > /etc/docker/daemon.json
# Restart docker to pick up the changes
sudo service docker restart
# Start the client (if you haven't already)
docker run --restart always --privileged --network host --env LCD_NUMBER -dt ghcr.io/asm/ansi_scroller_client:latest
# Now the important part: Stop docker and remove a directory it attempts to rename on boot.  OverlayFS doesn't support renaming.
sudo service docker stop
sudo rm -rf /var/lib/docker/runtimes
# Run raspi-config and enable overlayfs and read only /boot in "Performance Options", then reboot
sudo raspi-config
```
At this point, no file changes will survive a reboot. To make changes, just run `raspi-config` again and disable overlayfs.  More details on getting Docker working on OverlayFS can be found [here](https://github.com/docker/for-linux/issues/230#issuecomment-1035642872).

## Loading your own art
The server loads a list of ANSI artworks to display from a JSON list via a URL.  You can change that URL [here](https://github.com/asm/ansi_scroller/blob/master/bin/ansi_server.rb#L23).  You'll note the files are in the `.bin` format (not `.ans`).  This format is far easier to read and you can use [PabloDraw](http://picoe.ca/products/pablodraw/) to convert artwork.  Someday, I'll write the code necessary to read `.ans` files.

## Development
Checkout the code to build and run the docker images yourself by running:
```bash
sudo apt install -y git
git clone https://github.com/asm/ansi_scroller.git
cd ansi_scroller

# On the server:
docker build -f Dockerfile.server . -t ansi_scroller_server
docker run --privileged --network host -dt ansi_scroller_server

# On clients:
docker build -f Dockerfile.client . -t ansi_scroller_client
export LCD_NUMBER=xxx
docker run --privileged --network host --env LCD_NUMBER -dt ansi_scroller_client
```
### On Linux
To ease development, there is a [Docker compose](https://github.com/asm/ansi_scroller/blob/master/docker-compose.yml) file that will run on Linux and Chrome OS.  It launches a server and four displays, each in its own window.  To start it, run:

```bash
xhost +local:root
docker-compose up --build
```

## TODO
* Support `.ans` files.
