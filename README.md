# orangepi-pc-imagebuilder
OrangePi PC image building tool in docker

## Features
* Debian stretch rootfs
* Mainline kernel with OrangePi specific patches (https://github.com/rkojedzinszky/linux-kernel)
* Ready for Ansible bootstrap (openssh-server installed, python needs to be bootstrapped)
* Uses docker-compose for building

## Usage
Run
```
tools/install-on-sdcard
```

The resulting bootable image can be directly written to an SD card.

After first boot, run
```
/usr/local/sbin/expand-rootfs
```
to resize the root partition to fit the sdcard.

Default password:
```
root / passw0rd
```
