FROM debian:stretch-slim as sources

ENV LANG="C.UTF-8" \
    IMAGE_BUILDER="/usr/local/image-builder" \
    UBOOT_GIT_REPOSITORY="https://github.com/u-boot/u-boot.git" \
    UBOOT_COMMIT="HEAD"
ENV WORKDIR="${IMAGE_BUILDER}/workdir" \
    ASSETS="${IMAGE_BUILDER}/assets"

VOLUME "${WORKDIR}"

RUN dpkg --add-architecture armhf \
    && echo 'deb http://deb.debian.org/debian testing main' > /etc/apt/sources.list.d/testing.list \
    && printf 'Package: *\nPin: release o=Debian,a=testing\nPin-Priority: 300\n' > /etc/apt/preferences.d/testing \
    && apt-get update \
    && apt-get install -y \
      binfmt-support \
      git \
      build-essential \
      binutils-arm-linux-gnueabihf \
      gcc-6-arm-linux-gnueabihf-base \
      g++-6-arm-linux-gnueabihf \
      gcc-arm-linux-gnueabihf \
      cpp-arm-linux-gnueabihf \
      libusb-1.0-0 \
      libusb-1.0-0-dev \
      qemu-user-static \
      libfakeroot:armhf \
      libfakechroot:armhf \
      bison \
      flex \
      python \
      swig \
      python-dev \
      bc \
      pkg-config \
      libusb-dev \
      mmdebstrap/testing \
      parted \
      fuse2fs \
      fusefat \
      dosfstools \ 
      whois \
      libssl-dev \
    && rm -rf /var/lib/apt/lists/*

#      u-boot-tools \
#      binutils-arm-linux-gnueabihf \
#      gcc-6-arm-linux-gnueabihf-base \
#      g++-6-arm-linux-gnueabihf \
#      gcc-arm-linux-gnueabihf \
#      cpp-arm-linux-gnueabihf \
#      libusb-1.0-0 \
#      libusb-1.0-0-dev \
#      git \
#      wget \
#      fakeroot \
#      zlib1g-dev \
#      libncurses5-dev \
#      bison \
#      flex \
#      python \
#      swig \
#      python-dev \
#      bc \
#      pkg-config \
#      libusb-dev \
#      kmod \
#      vim \
#      debootstrap \
#      qemu-user-static \
#      fakechroot \
#      mmdebstrap/testing \
#      parted \
#      fuse2fs \
#      fusefat \
#      dosfstools 
#      whois \
#      libfakeroot:armhf \
#      libfakechroot:armhf \

COPY docker-entrypoint.sh /
COPY assets "${ASSETS}"
#COPY boot.cmd /
#COPY Makefile /

ENTRYPOINT ["/docker-entrypoint.sh"]
