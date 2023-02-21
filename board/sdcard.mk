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

# Image size variables
BOOT_START := 8
ROOTFS_START := $(shell echo $(BOOT_START)+$(BOOT_SIZE_MB) | bc)
UBOOT_START := 66# Cribbed from Yocto.
SDIMAGE_SIZE_MB := $(shell echo $(ROOTFS_START)+$(ROOTFS_SIZE_MB) | bc)

SDCARD_WIP_PATH := $(PRODUCT_OUT)/sdcard_$(USERSPACE_ARCH).img.wip
SDCARD_PATH := $(PRODUCT_OUT)/sdcard_$(USERSPACE_ARCH).img

sdcard: $(SDCARD_PATH)
sdcard-xz: $(SDCARD_PATH).xz

$(SDCARD_PATH): $(ROOTDIR)/build/rootfs.mk \
                $(ROOTDIR)/board/boot.mk \
                $(ROOTDIR)/board/fstab.sdcard \
                | $(PRODUCT_OUT)/u-boot.imx \
                $(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img \
                $(PRODUCT_OUT)/obj/ROOTFS/rootfs_$(USERSPACE_ARCH).patched.img \
                out-dirs
	fallocate -l $(SDIMAGE_SIZE_MB)M $(SDCARD_WIP_PATH)
	parted -s $(SDCARD_WIP_PATH) mklabel msdos
	parted -s $(SDCARD_WIP_PATH) unit MiB mkpart primary ext2 $(BOOT_START) $(ROOTFS_START)
	parted -s $(SDCARD_WIP_PATH) unit MiB mkpart primary ext4 $(ROOTFS_START) 100%
	dd if=$(PRODUCT_OUT)/u-boot.imx of=$(SDCARD_WIP_PATH) conv=notrunc seek=$(UBOOT_START) bs=512
	dd if=$(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img of=$(SDCARD_WIP_PATH) conv=notrunc seek=$(BOOT_START) bs=1M
	dd if=$(PRODUCT_OUT)/obj/ROOTFS/rootfs_$(USERSPACE_ARCH).patched.img \
		of=$(SDCARD_WIP_PATH) conv=notrunc seek=$(ROOTFS_START) bs=1M

	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	$(ROOTDIR)/board/make_sdcard.sh $(ROOTFS_DIR) $(SDCARD_WIP_PATH) $(ROOTDIR)
	rmdir $(ROOTFS_DIR)

	mv $(SDCARD_WIP_PATH) $(SDCARD_PATH)

$(SDCARD_PATH).xz: $(SDCARD_PATH)
	xz -k -T0 -0 $(SDCARD_PATH)

targets::
	@echo "sdcard     - generate a flashable sdcard image"

clean::
	rm -f $(PRODUCT_OUT)/sdcard_*.img $(PRODUCT_OUT)/sdcard_*.img.xz

.PHONY:: sdcard sdcard-xz
