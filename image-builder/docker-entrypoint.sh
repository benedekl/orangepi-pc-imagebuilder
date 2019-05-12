#!/bin/sh
set -xue

echo Hello,
echo This is Debian Image Builder for the OrangePi PC.

# Enable foreign architecture in binfmts
# Needed for package installation in rootfs
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
update-binfmts --enable qemu-arm

cd "${WORKDIR}"

if [ $# -ne 0 ] ; then
    exec "$@"
else
    #rm .uboot_configured
#    rm -f .boot*
#    rm -f boot.img boot.cmd bootp?.*
    make -f "${ASSETS}/Makefile"
fi
