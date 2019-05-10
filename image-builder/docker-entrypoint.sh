#!/bin/sh
set -xue

echo Hello,
echo This is Debian Image Builder for the OrangePi PC.

# enable foreign architecture in binfmts
# needed for package installation in rootfs
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
update-binfmts --enable qemu-arm

cd ${BUILD_ROOT}

if [ $# -ne 0 ] ; then
    exec "$@"
else
    #rm .uboot_configured
    rm -f .boot*
    rm -f boot.img boot.cmd bootp?.*
    make -f /Makefile
fi
