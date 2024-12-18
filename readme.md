# OSWorld Docker Image for macOS
This is a Docker image containing the virtual machine environment of OSWorld, based on [dockur/macos](https://github.com/dockur/macos).

## Test the image
This image should be used inside the environment of [OSWorld](https://github.com/xlang-ai/OSWorld). However, if you are interested in testing the image, you may use the command

```
docker run -it -p 5000:5000 -p 9222:9222 -p 8080:8080 -p 8006:8006 -e DISK_FMT=qcow2 --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN --stop-timeout 120 --volume /ABSOLUTE/PATH/TO/macOS.qcow2:/storage/macOS.qcow2 happysixd/osworld-docker-macos
```

Remember to replace `/ABSOLUTE/PATH/TO/macOS.qcow2` with the absolute path to the image file.

The virtual machine should be launched in the background after running the command. Wait a few seconds, and go to `localhost:8006` to view the graphical desktop.
