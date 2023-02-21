# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

FLASHCARD_ROOTFS_START := 8
FLASHCARD_ROOTFS_SIZE_MB := $(shell echo $(ROOTFS_SIZE_MB)+$(BOOT_SIZE_MB)+32 | bc)
FLASHCARD_SIZE_MB := $(shell echo $(FLASHCARD_ROOTFS_START)+$(FLASHCARD_ROOTFS_SIZE_MB) | bc)

FLASHCARD_PATH := $(PRODUCT_OUT)/flashcard_$(USERSPACE_ARCH).img
FLASHCARD_XZ_PATH := $(PRODUCT_OUT)/flashcard_$(USERSPACE_ARCH).img.xz
FLASHCARD_WORK_DIR := $(PRODUCT_OUT)/flashcard-work
FLASHCARD_WIP_PATH := $(FLASHCARD_WORK_DIR)/flashcard.img
FLASHCARD_MOUNT_PATH := $(FLASHCARD_WORK_DIR)/mount
FLASHCARD_BOOT_MOUNT_PATH := $(FLASHCARD_WORK_DIR)/mount_boot
flashcard: $(FLASHCARD_PATH)

$(FLASHCARD_PATH): $(ROOTDIR)/board/flashcard/init $(ROOTDIR)/board/flashcard/boot.txt multistrap | \
                   busybox partition-table $(PRODUCT_OUT)/u-boot.imx $(HOST_OUT)/bin/mkimage home_raw
	# TODO(math the size)
	-rm -rf $(FLASHCARD_WORK_DIR)
	mkdir -p $(FLASHCARD_WORK_DIR)

	# Build folder structure for initramfs
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/bin
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/dev
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/proc
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/sys
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/usr/bin
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/usr/sbin
	mkdir -p $(FLASHCARD_WORK_DIR)/initramfs/sbin

	# Install basic /dev nodes
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/console c 5 1
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/null c 1 3
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/tty c 5 0
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/ttymxc0 c 207 16
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/tty0 c 4 0
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/urandom c 1 9
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/random c 1 8
	sudo mknod $(FLASHCARD_WORK_DIR)/initramfs/dev/zero c 1 5

	# Install init and busybox
	cp $(ROOTDIR)/board/flashcard/init $(FLASHCARD_WORK_DIR)/initramfs/init
	cp $(PRODUCT_OUT)/busybox $(FLASHCARD_WORK_DIR)/initramfs/bin/busybox

	# Generate gzip'd initramfs archive
	cd $(FLASHCARD_WORK_DIR)/initramfs; find . | cpio -o -H newc | gzip > $(FLASHCARD_WORK_DIR)/initramfs.cpio.gz

	fallocate -l $(FLASHCARD_ROOTFS_SIZE_MB)M $(FLASHCARD_WIP_PATH)
	mkfs.ext2 $(FLASHCARD_WIP_PATH)
	mkdir -p $(FLASHCARD_MOUNT_PATH)
	mkdir -p $(FLASHCARD_BOOT_MOUNT_PATH)
	sudo mount -o loop $(FLASHCARD_WIP_PATH) $(FLASHCARD_MOUNT_PATH) 
	sudo mount -o loop,ro $(PRODUCT_OUT)/multistrap/boot_$(USERSPACE_ARCH).img $(FLASHCARD_BOOT_MOUNT_PATH)
	sudo chown $(USER) $(FLASHCARD_MOUNT_PATH)

	$(HOST_OUT)/bin/mkimage -A arm64 \
	                        -O linux \
	                        -T ramdisk \
	                        -C gzip \
	                        -n "initramfs" \
	                        -d $(FLASHCARD_WORK_DIR)/initramfs.cpio.gz \
	                        $(FLASHCARD_MOUNT_PATH)/initramfs.cpio.gz.uboot

	$(HOST_OUT)/bin/mkimage -A arm \
	                        -T script \
	                        -O linux \
	                        -d $(ROOTDIR)/board/flashcard/boot.txt \
	                        $(FLASHCARD_MOUNT_PATH)/boot.scr

	cp $(FLASHCARD_BOOT_MOUNT_PATH)/Image $(FLASHCARD_MOUNT_PATH)
	cp $(FLASHCARD_BOOT_MOUNT_PATH)/*.dtb $(FLASHCARD_MOUNT_PATH)
	cp $(PRODUCT_OUT)/partition-table-*.img $(FLASHCARD_MOUNT_PATH)
	cp $(PRODUCT_OUT)/u-boot.imx $(FLASHCARD_MOUNT_PATH)
	cp $(PRODUCT_OUT)/multistrap/boot_$(USERSPACE_ARCH).img $(FLASHCARD_MOUNT_PATH)/boot.img
	cp $(PRODUCT_OUT)/multistrap/rootfs_$(USERSPACE_ARCH).img.wip $(FLASHCARD_MOUNT_PATH)/rootfs.img
	cp $(PRODUCT_OUT)/obj/HOME/home.raw.img $(FLASHCARD_MOUNT_PATH)/home.img

	sudo umount $(FLASHCARD_BOOT_MOUNT_PATH)
	sudo umount $(FLASHCARD_MOUNT_PATH)

	fallocate -l $(FLASHCARD_SIZE_MB)M $(FLASHCARD_PATH)
	parted -s $(FLASHCARD_PATH) mklabel msdos
	parted -s $(FLASHCARD_PATH) unit MiB mkpart primary ext2 $(BOOT_START) 100%
	dd if=$(PRODUCT_OUT)/u-boot.imx of=$(FLASHCARD_PATH) conv=notrunc seek=$(UBOOT_START) bs=512
	dd if=$(FLASHCARD_WIP_PATH) of=$(FLASHCARD_PATH) conv=notrunc seek=$(BOOT_START) bs=1M

	rm -rf $(FLASHCARD_WORK_DIR)
	touch $(FLASHCARD_PATH)

targets::
	@echo "flashcard - SD Card image to flash eMMC"

clean::
	rm -rf $(PRODUCT_OUT)/flashcard_*.img

.PHONY:: flashcard
