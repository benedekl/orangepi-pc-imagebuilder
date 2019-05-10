# Makefile for building the bootable sdcard image
#
# steps needed:
# u-boot:
#   clone source
#   configure
#   build loader
#   compile boot.cmd
#
# linux kernel:
#   clone source
#   (apply patches)
#   configure
#   build zImage
#   build device tree
#   build modules
#   install modules
#
# rootfs:
#   debootstrap
#
# boot.img:
#   create empty file for the disk image
#   create partitions
#   copy u-boot loader into the image
#   create filesystem images in separate files
#   populate filesystems
#   copy filesystem images back into the image file


all: .linux_done .boot_ready rootfs.tgz

.uboot_cloned:
	git clone https://github.com/u-boot/u-boot.git u-boot
	touch $@

.uboot_configured: .uboot_cloned
	cd u-boot && make CROSS_COMPILE=arm-linux-gnueabihf- orangepi_pc_defconfig
	touch $@

.uboot_built: .uboot_configured
	cd u-boot && make CROSS_COMPILE=arm-linux-gnueabihf- -j4
	touch $@

boot.cmd:
	cat /boot.cmd > $@
#	echo 'setenv stdout=serial,vga' > $@
#	echo 'setenv stderr=serial,vga' >> $@
#	echo 'setenv video-mode sunxi:1024x768-24@60,monitor=dvi,hpd=0,edid=0' >> $@
#	echo 'fatload mmc 0 0x46000000 boot/zImage' >> $@
#	echo 'fatload mmc 0 0x49000000 boot/dtbs/sun8i-h3-orangepi-pc.dtb' >> $@
#	echo 'setenv bootargs console=ttyS0,115200 console=tty0 earlyprintk root=/dev/mmcblk0p2 rootwait panic=1' >> $@
#	echo 'bootz 0x46000000 - 0x49000000' >> $@

boot.scr: .uboot_built boot.cmd
	u-boot/tools/mkimage -C none -A arm -T script -d boot.cmd $@

.uboot_done: boot.scr
	touch $@



.sunxi_tools_cloned:
	git clone https://github.com/linux-sunxi/sunxi-tools.git sunxi-tools
	touch $@

.sunxi_boards_cloned:
	git clone https://github.com/linux-sunxi/sunxi-boards.git sunxi-boards
	touch $@



.linux_cloned:
	git clone --branch v5.0 --depth 1 https://github.com/torvalds/linux.git linux
	touch $@

.linux_configured: .linux_cloned
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sunxi_defconfig
	touch $@

.linux_image_built: .linux_configured
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 zImage
	touch $@

.linux_dtbs_built: .linux_configured
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 dtbs
	touch $@

.linux_modules_built: .linux_configured
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 modules
	touch $@

.linux_modules_installed: .linux_modules_built
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
	touch $@

.linux_done: .linux_image_built .linux_dtbs_built .linux_modules_installed
	touch $@



rootfs.tgz:
	#mmdebstrap --variant=minbase --architectures=armhf --mode=fakechroot --verbose \
	#	--include systemd-sysv,udev,sudo,vim,libpam-runtime,iproute2,dhclient,resolvconf \
	#	stretch rootfs.tgz
	mmdebstrap --architectures=armhf --mode=fakechroot --verbose --debug \
		--setup-hook='mount -o bind "/dev/random" "$$1/dev/random"' \
		--setup-hook='mount -o bind "/dev/urandom" "$$1/dev/urandom"' \
		--customize-hook='umount "$$1/dev/random"' \
		--customize-hook='umount "$$1/dev/urandom"' \
		--essential-hook='echo tzdata tzdata/Areas select Europe | chroot "$$1" debconf-set-selections' \
		--essential-hook='echo tzdata tzdata/Zones/Europe select Budapest | chroot "$$1" debconf-set-selections' \
		--include vim,haveged,openssh-server \
		stretch rootfs.tgz
	#--essential-hook='sed -i "1c#!/bin/sh -x" $$1/var/lib/dpkg/info/openssh-server.postinst' \



# .bootimg_created:
# 	truncate -s 3500M "boot.img"
# 	touch $@
# 
# .bootimg_parted: .bootimg_created
# 	parted -s boot.img mklabel msdos
# 	parted -s -a none boot.img mkpart primary fat32 0 20M
# 	parted -s -a none boot.img mkpart primary ext4 20M 100%
# 	touch $@



boot.img:
	truncate -s 300M $@

.bootimg_parted: boot.img
	parted -s $< mklabel msdos
	parted -s -a none $< mkpart primary fat32 2048s 20M
	parted -s -a none $< mkpart primary ext4 20M 100%
	touch $@

partitions: .bootimg_parted
	parted boot.img unit s print > $@

bootp1.img: partitions
	truncate -s $$(awk '/^ 1 / { gsub("s","",$$4); printf "%d\n", $$4*512 }' partitions) $@

bootp2.img: partitions
	truncate -s $$(awk '/^ 2 / { gsub("s","",$$4); printf "%d\n", $$4*512 }' partitions) $@

.bootp1_mkfs: bootp1.img
	mkfs -t vfat $<
	touch $@

.bootp2_mkfs: bootp2.img
	mkfs -t ext4 $<
	touch $@



.uboot_burnt: partitions .uboot_done
	dd conv=notrunc if=/dev/zero of=boot.img bs=512 count=2047 seek=1
	dd conv=notrunc if=u-boot/u-boot-sunxi-with-spl.bin of=boot.img bs=512 seek=16
	touch $@

part1_mnt:
	mkdir -p $@

part2_mnt:
	mkdir -p $@

.part1_filled: .linux_image_built .linux_dtbs_built boot.scr .bootp1_mkfs | part1_mnt
	fusefat -o rw+ bootp1.img part1_mnt
	mkdir -p part1_mnt/boot/dtbs
	cp linux/arch/arm/boot/zImage part1_mnt/boot/zImage
	cp linux/arch/arm/boot/dts/sun8i-h3-orangepi-pc.dtb part1_mnt/boot/dtbs/sun8i-h3-orangepi-pc.dtb
	cp boot.scr part1_mnt/boot/boot.scr
	fusermount -u part1_mnt
	touch $@

.part2_filled: rootfs.tgz .linux_modules_installed .bootp2_mkfs | part2_mnt
	fuse2fs bootp2.img part2_mnt
	tar -xzvf rootfs.tgz -C part2_mnt
	#sed -i '/^root:/s/\*//' part2_mnt/etc/shadow
	sed -i '/^root:/croot:'$$(mkpasswd -m sha-512 passw0rd)':17261:0:99999:7:::' part2_mnt/etc/shadow
	sed -i '/PermitRootLogin/cPermitRootLogin yes' part2_mnt/etc/ssh/sshd_config
	cp -r /rootfs/. part2_mnt/
	mkdir -p part2.mnt/lib
	cp -r linux/output/lib/modules part2_mnt/lib
	fusermount -u part2_mnt
	fsck.ext4 -fp bootp2.img || [ $$? -eq 1 ]
	touch $@

.part1_burnt: .part1_filled
	dd conv=notrunc if=bootp1.img of=boot.img bs=512 seek=$$(awk '/^ 1 / { gsub("s","",$$2); printf "%d\n", $$2 }' partitions)
	touch $@

.part2_burnt: .part2_filled
	dd conv=notrunc if=bootp2.img of=boot.img bs=512 seek=$$(awk '/^ 2 / { gsub("s","",$$2); printf "%d\n", $$2 }' partitions)
	touch $@

.boot_ready: .uboot_burnt .part1_burnt .part2_burnt
	touch $@


clean:
	[ -f .uboot_cloned ] && cd u-boot && git clean -df
	rm -f .uboot_configured .uboot_built
	rm -rf boot.cmd boot.scr
	[ -f .sunxi_tools_cloned ] && cd sunxi-tools && git clean -df
	[ -f .sunxi_boards_cloned ] && cd sunxi-boards && git clean -df
	[ -f .linux_cloned ] && cd linux && git clean -df
	rm -f .linux_configured .linux_image_built .linux_dtbs_built .linux_modules_built .linux_modules_installed
	rm -f rootfs.tgz



PHONY: clean distclean


	# git clone https://github.com/linux-sunxi/sunxi-tools.git ${BUILD_ROOT}/sunxi-tools
	# git clone https://github.com/linux-sunxi/sunxi-boards.git ${BUILD_ROOT}/sunxi-boards
	# git clone --branch v5.0 --depth 1 https://github.com/torvalds/linux.git ${BUILD_ROOT}/linux
	# 
	# ## u-boot
	# #cd /usr/local/src/u-boot
	# #
	# #make CROSS_COMPILE=arm-linux-gnueabihf- orangepi_pc_defconfig
	# ##make CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
	# #make CROSS_COMPILE=arm-linux-gnueabihf-
	# #
	# ## sunxi-tools
	# #cd /usr/local/src/sunxi-tools
	# #
	# #make
	# #
	# ## sunxi-boards
	# #cd /usr/local/src/sunxi-boards
	# #
	# #/usr/local/src/sunxi-tools/fex2bin sys_config/h3/xunlong_orange_pi_pc.fex script.bin
	# #
	# 
	# # kernel
	# cd /usr/local/src/linux
	# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sunxi_defconfig
	# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 zImage
	# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 dtbs
	# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 modules
	# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
