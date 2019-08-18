build:
	docker run --rm -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix -it ansi_scroller
image:
	docker build . -t ansi_scroller
