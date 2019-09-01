# Raspberry Pi ANSI scroller

Quickstart:
```
# This version of docker is the only one that seems to work on RPis at the moment
curl -fsSL https://get.docker.com | VERSION=18.06.3 sh
sudo apt install -y git
git clone git@github.com:asm/ansi_scroller.git
cd ansi_scroller
docker build . -t ansi_scroller
docker run --restart always --privileged --network host --env LCD_NUMBER=$LCD_NUMBER -dt ansi_scroller
```
