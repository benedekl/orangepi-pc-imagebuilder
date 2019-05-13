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


UBOOT_REPOSITORY:=https://github.com/u-boot/u-boot.git
LINUX_REPOSITORY:=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
LINUX_VERSION=4.19.42


all: .finished

.uboot_cloned:
	git clone "${UBOOT_REPOSITORY}" u-boot
	touch $@

.uboot_configured: .uboot_cloned
	cd u-boot && make CROSS_COMPILE=arm-linux-gnueabihf- orangepi_pc_defconfig
	touch $@

u-boot/u-boot-sunxi-with-spl.bin u-boot/tools/mkimage: .uboot_configured
	cd u-boot && make CROSS_COMPILE=arm-linux-gnueabihf- -j4

boot.cmd:
	cat "$$ASSETS/boot.cmd" > $@

boot.scr: u-boot/tools/mkimage boot.cmd
	u-boot/tools/mkimage -C none -A arm -T script -d boot.cmd $@



.linux_cloned:
	git clone --branch "v${LINUX_VERSION}" --depth 1 "${LINUX_REPOSITORY}" linux
	touch $@

.linux_configured: .linux_cloned
	cp "$$ASSETS/kernel-config" linux/.config
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- oldconfig
	touch $@

linux/arch/arm/boot/zImage: .linux_configured
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 zImage

linux/arch/arm/boot/dts/sun8i-h3-orangepi-pc.dtb: .linux_configured
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 dtbs

.linux_modules_built: .linux_configured
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 modules
	touch $@

.linux_modules_installed: .linux_modules_built
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
	touch $@



rootfs.tgz:
	# The /dev/random and /dev/urandom must be bind mounted to be usable.
	# Witout mounting them the openssh-server package installation fails.
	mmdebstrap --architectures=armhf --mode=fakechroot --verbose --debug \
		--setup-hook='mount -o bind "/dev/random" "$$1/dev/random"' \
		--setup-hook='mount -o bind "/dev/urandom" "$$1/dev/urandom"' \
		--customize-hook='umount "$$1/dev/random"' \
		--customize-hook='umount "$$1/dev/urandom"' \
		--essential-hook='echo tzdata tzdata/Areas select Europe | chroot "$$1" debconf-set-selections' \
		--essential-hook='echo tzdata tzdata/Zones/Europe select Budapest | chroot "$$1" debconf-set-selections' \
		--include u-boot-tools,cpufrequtils,initramfs-tools,openssh-server \
		stretch rootfs.tgz



boot.img:
	rm -f $@
	truncate -s 400M $@

.bootimg_parted: boot.img
	parted -s $< mklabel msdos
	parted -s -a optimal $< mkpart primary ext3 2048s 20M
	parted -s -a optimal $< mkpart primary ext4 20M 100%
	touch $@

partitions: .bootimg_parted
	parted boot.img unit s print > $@

bootp1.img: partitions
	rm -f $@
	truncate -s $$(awk '/^ 1 / { gsub("s","",$$4); printf "%d\n", $$4*512 }' partitions) $@

bootp2.img: partitions
	rm -f $@
	truncate -s $$(awk '/^ 2 / { gsub("s","",$$4); printf "%d\n", $$4*512 }' partitions) $@

.bootp1_mkfs: bootp1.img
	mkfs -t ext3 $<
	touch $@

.bootp2_mkfs: bootp2.img
	mkfs -t ext4 $<
	touch $@



.uboot_burnt: partitions u-boot/u-boot-sunxi-with-spl.bin
	dd conv=notrunc if=/dev/zero of=boot.img bs=512 count=2047 seek=1
	dd conv=notrunc if=u-boot/u-boot-sunxi-with-spl.bin of=boot.img bs=512 seek=16
	touch $@

part2_mnt:
	mkdir -p $@

.part2_filled: linux/arch/arm/boot/zImage linux/arch/arm/boot/dts/sun8i-h3-orangepi-pc.dtb boot.scr .bootp1_mkfs rootfs.tgz .linux_modules_installed .bootp2_mkfs | part2_mnt
	fuse2fs bootp2.img part2_mnt
	# rootfs
	tar -xzf rootfs.tgz -C part2_mnt
	mkdir -p part2.mnt/lib
	cp -R linux/output/lib/modules part2_mnt/lib
	cp /usr/bin/qemu-arm-static part2_mnt/usr/bin
	# boot
	mkdir -p part2_mnt/boot
	fuse2fs bootp1.img part2_mnt/boot
	mkdir -p part2_mnt/boot/dtb
	cp linux/arch/arm/boot/zImage part2_mnt/boot/vmlinuz-${LINUX_VERSION}
	cp linux/arch/arm/boot/dts/sun8i-h3-orangepi-pc.dtb part2_mnt/boot/dtb/sun8i-h3-orangepi-pc.dtb
	echo "root=UUID=$$(blkid -o value -s UUID bootp2.img)" > "part2_mnt/boot/bootEnv.txt"
	echo "UUID=$$(blkid -o value -s UUID bootp1.img) /boot ext3 defaults,commit=600 0 1" > "part2_mnt/etc/fstab"
	echo "UUID=$$(blkid -o value -s UUID bootp2.img) / ext4 defaults,commit=600 0 1" >> "part2_mnt/etc/fstab"
	cp boot.scr part2_mnt/boot/boot.scr
	$$ASSETS/chroot-wrapper part2_mnt /usr/sbin/update-initramfs -c -k ${LINUX_VERSION}
	# fixups
	sed -i '/^root:/croot:'$$(mkpasswd -m sha-512 passw0rd)':17261:0:99999:7:::' part2_mnt/etc/shadow
	sed -i '/PermitRootLogin/cPermitRootLogin yes' part2_mnt/etc/ssh/sshd_config
	cp -R "${ASSETS}/rootfs/." part2_mnt/
	$$ASSETS/chroot-wrapper part2_mnt /etc/kernel/postinst.d/zz_boot ${LINUX_VERSION}
	rm part2_mnt/usr/bin/qemu-arm-static
	fusermount -u part2_mnt/boot
	fusermount -u part2_mnt
	fsck.ext3 -fp bootp1.img || [ $$? -eq 1 ]
	fsck.ext4 -fp bootp2.img || [ $$? -eq 1 ]
	touch $@

.part1_burnt: partitions .part2_filled
	dd conv=notrunc if=bootp1.img of=boot.img bs=512 seek=$$(awk '/^ 1 / { gsub("s","",$$2); printf "%d\n", $$2 }' partitions)
	touch $@

.part2_burnt: partitions .part2_filled
	dd conv=notrunc if=bootp2.img of=boot.img bs=512 seek=$$(awk '/^ 2 / { gsub("s","",$$2); printf "%d\n", $$2 }' partitions)
	touch $@

.finished: .uboot_burnt .part1_burnt .part2_burnt
	echo "boot.img ready to flash."
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
