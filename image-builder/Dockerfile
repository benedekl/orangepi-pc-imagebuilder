FROM debian:stretch-slim

ENV LANG C.UTF-8
ENV BUILD_ROOT /usr/local/build

RUN dpkg --add-architecture armhf \
    && echo 'deb http://deb.debian.org/debian testing main' > /etc/apt/sources.list.d/testing.list \
    && printf 'Package: *\nPin: release o=Debian,a=testing\nPin-Priority: 300\n' > /etc/apt/preferences.d/testing \
    && apt-get update \
    && apt-get install -y \
      build-essential u-boot-tools binutils-arm-linux-gnueabihf gcc-6-arm-linux-gnueabihf-base \
      g++-6-arm-linux-gnueabihf gcc-arm-linux-gnueabihf cpp-arm-linux-gnueabihf libusb-1.0-0 libusb-1.0-0-dev \
      git wget fakeroot zlib1g-dev libncurses5-dev bison flex python swig python-dev bc pkg-config libusb-dev \
      kmod vim debootstrap qemu-user-static fakechroot binfmt-support mmdebstrap/testing \
      parted fuse2fs fusefat dosfstools whois libfakeroot:armhf libfakechroot:armhf \
    && rm -rf /var/lib/apt/lists/*

#RUN git clone https://github.com/u-boot/u-boot.git ${BUILD_ROOT}/u-boot
#RUN git clone https://github.com/linux-sunxi/sunxi-tools.git ${BUILD_ROOT}/sunxi-tools
#RUN git clone https://github.com/linux-sunxi/sunxi-boards.git ${BUILD_ROOT}/sunxi-boards
#RUN git clone --branch v5.0 --depth 1 https://github.com/torvalds/linux.git ${BUILD_ROOT}/linux

COPY docker-entrypoint.sh /
COPY rootfs /rootfs
COPY boot.cmd /
COPY Makefile /

VOLUME ${BUILD_ROOT}

ENTRYPOINT ["/docker-entrypoint.sh"]
