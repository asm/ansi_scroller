# Raspberry Pi ANSI scroller

Quickstart:
```
# This version of docker is the only one that seems to work on RPis at the moment
curl -fsSL https://get.docker.com | VERSION=18.06.3 sh
sudo apt install -y git
git clone git@github.com:asm/ansi_scroller.git
cd ansi_scroller
docker build -f Dockerfile.server . -t ansi_scroller_server
docker build -f Dockerfile.client . -t ansi_scroller_client
docker run --restart always --privileged --network host -dt ansi_scroller_server
docker run --restart always --privileged --network host --env LCD_NUMBER -dt ansi_scroller_client
```

## Development Using Docker
Quickstart:
```
xhost +local:root
docker-compose up --build
```

