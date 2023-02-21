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

ROOTFS_DIR := $(PRODUCT_OUT)/obj/ROOTFS/rootfs
ROOTFS_IMG := $(PRODUCT_OUT)/rootfs_$(USERSPACE_ARCH).img
ROOTFS_RAW_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs_$(USERSPACE_ARCH).raw.img
ROOTFS_PATCHED_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs_$(USERSPACE_ARCH).patched.img
ROOTFS_RAW_LOCAL_CACHE_PATH := $(ROOTDIR)/cache/rootfs_$(USERSPACE).raw.img

ifeq ($(HEADLESS_BUILD),)
    $(info )
    $(info *** GUI build selected -- set HEADLESS_BUILD=true if this is not what you intend.)
	PRE_INSTALL_PACKAGES := $(BOARD_NAME)-core $(BOARD_NAME)-gui
else
    $(info )
    $(info *** Headless build selected -- unset HEADLESS_BUILD if this is not what you intend.)
	PRE_INSTALL_PACKAGES := $(BOARD_NAME)-core
endif

ifeq ($(FETCH_PACKAGES),true)
    $(info *** Using prebuilt packages, set FETCH_PACKAGES=false to build locally)
else
    $(info *** Building packages locally, set FETCH_PACKAGES=true to use prebuilts)
endif

$(ROOTFS_DIR):
	mkdir -p $(ROOTFS_DIR)

rootfs: $(ROOTFS_IMG)
	$(LOG) rootfs finished

rootfs_raw: $(ROOTFS_RAW_IMG)

adjustments:
	$(LOG) rootfs adjustments
	sudo $(ROOTDIR)/build/fix_permissions.sh -p $(ROOTDIR)/build/permissions.txt -t $(ROOTFS_DIR)

ifneq ($(ROOTFS_RAW_CACHE_DIRECTORY),)
$(ROOTFS_RAW_IMG): $(ROOTFS_RAW_CACHE_DIRECTORY)/rootfs_$(USERSPACE_ARCH).raw.img
	$(LOG) rootfs raw-fetch
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $< $<.sha256sum $(dir $(ROOTFS_RAW_IMG))
	$(LOG) rootfs raw-fetch finished
else ifeq ($(shell test -f $(ROOTFS_RAW_LOCAL_CACHE_PATH) && echo found),found)
$(ROOTFS_RAW_IMG): $(ROOTFS_RAW_LOCAL_CACHE_PATH)
	$(LOG) rootfs raw-cache
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $(ROOTFS_RAW_LOCAL_CACHE_PATH) $(ROOTFS_RAW_IMG)
	cd $(dir $(ROOTFS_RAW_IMG)); sha256sum $(notdir $(ROOTFS_RAW_IMG)) > $(ROOTFS_RAW_IMG).sha256sum
	$(LOG) rootfs raw-cache finished
else
$(ROOTFS_RAW_IMG): $(ROOTDIR)/build/preamble.mk $(ROOTDIR)/build/rootfs.mk /usr/bin/qemu-$(QEMU_ARCH)-static /tmp/multistrap
	$(LOG) rootfs raw-build
	mkdir -p $(ROOTFS_DIR)
	rm -f $(ROOTFS_RAW_IMG)
	fallocate -l $(ROOTFS_SIZE_MB)M $(ROOTFS_RAW_IMG)
	mkfs.ext4 -F -j $(ROOTFS_RAW_IMG)
	tune2fs -o discard $(ROOTFS_RAW_IMG)
	-sudo umount $(ROOTFS_DIR)/dev
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_RAW_IMG) $(ROOTFS_DIR)

	cp $(ROOTDIR)/board/multistrap.conf $(PRODUCT_OUT)/multistrap.conf
	sed -i -e 's/RELEASE_NAME/$(RELEASE_NAME)/g' $(PRODUCT_OUT)/multistrap.conf

	sed -i -e 's/MAIN_PACKAGES/$(PACKAGES_EXTRA)/g' $(PRODUCT_OUT)/multistrap.conf
	sed -i -e 's/USERSPACE_ARCH/$(USERSPACE_ARCH)/g' $(PRODUCT_OUT)/multistrap.conf

	$(LOG) rootfs raw-build multistrap
# TODO(jtgans): EWW! RIP THIS OUT WHEN BUSTER IS FIXED! EWW!
	sudo /tmp/multistrap -f $(PRODUCT_OUT)/multistrap.conf -d $(ROOTFS_DIR)
	$(LOG) rootfs raw-build multistrap finished

	sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	sudo cp /usr/bin/qemu-$(QEMU_ARCH)-static $(ROOTFS_DIR)/usr/bin

	$(LOG) rootfs raw-build dpkg-configure
	# Configure base-passwd first since a bunch of things relies on /etc/passwd existing without base-passwd as a dep.
	# python2.7-minimal requires (m)awk
	# See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=924401
	# TODO(jtgans): Find out how debootstrap handles this.
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $(ROOTFS_DIR) dpkg --configure \
		gcc-8-base libgcc1 libc6 libdebconfclient0 base-passwd mawk
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $(ROOTFS_DIR) dpkg --configure -a
	$(LOG) rootfs raw-build dpkg-configure finished

	sudo rm -f $(ROOTFS_DIR)/usr/bin/qemu-$(QEMU_ARCH)-static
	sudo umount $(ROOTFS_DIR)/dev
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_RAW_IMG)
	sudo chown ${USER} $(ROOTFS_RAW_IMG)
	cd $(dir $(ROOTFS_RAW_IMG)); sha256sum $(notdir $(ROOTFS_RAW_IMG)) > $(ROOTFS_RAW_IMG).sha256sum
	$(LOG) rootfs raw-build finished
endif

ROOTFS_PATCHED_DEPS := $(ROOTFS_RAW_IMG) \
                       $(ROOTDIR)/board/fstab.emmc \
                       $(ROOTDIR)/board/boot.mk

ifeq ($(FETCH_PACKAGES),false)
    ROOTFS_PATCHED_DEPS += $(ROOTDIR)/cache/packages.tgz
endif

$(ROOTFS_PATCHED_IMG): $(ROOTFS_PATCHED_DEPS) \
                       | $(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img \
                         /usr/bin/qemu-$(QEMU_ARCH)-static \
                         $(ROOTFS_DIR)
	$(LOG) rootfs patch
	cp $(ROOTFS_RAW_IMG) $(ROOTFS_PATCHED_IMG).wip
	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_PATCHED_IMG).wip $(ROOTFS_DIR)
	-sudo mkdir -p $(ROOTFS_DIR)/boot
	sudo mount -o loop $(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img $(ROOTFS_DIR)/boot
	-sudo mkdir -p $(ROOTFS_DIR)/dev
	sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	sudo cp /usr/bin/qemu-$(QEMU_ARCH)-static $(ROOTFS_DIR)/usr/bin

	sudo cp $(ROOTDIR)/board/fstab.emmc $(ROOTFS_DIR)/etc/fstab

	$(LOG) rootfs patch keyring
	echo 'nameserver 8.8.8.8' | sudo tee $(ROOTFS_DIR)/etc/resolv.conf

ifeq ($(FETCH_PACKAGES),false)
	echo 'deb [trusted=yes] file:///opt/aiy/packages ./' | sudo tee $(ROOTFS_DIR)/etc/apt/sources.list.d/local.list
	sudo mkdir -p $(ROOTFS_DIR)/opt/aiy
	sudo tar -xvf $(ROOTDIR)/cache/packages.tgz -C $(ROOTFS_DIR)/opt/aiy/
endif

	echo 'deb https://deb.debian.org/debian-security/ buster/updates main' |sudo tee $(ROOTFS_DIR)/etc/apt/sources.list.d/security.list
	echo 'deb-src https://deb.debian.org/debian-security/ buster/updates main' |sudo tee -a $(ROOTFS_DIR)/etc/apt/sources.list.d/security.list
	sudo cp $(ROOTDIR)/build/99network-settings $(ROOTFS_DIR)/etc/apt/apt.conf.d/

	#TODO(jtgans): This must go away.
	echo -e 'Acquire::Check-Valid-Until "false";\nAcquire::AllowInsecureRepositories "true";\nAcquire::AllowDowngradeToInsecureRepositories "true";' | sudo tee $(ROOTFS_DIR)/etc/apt/apt.conf.d/99-enable-unsecure-repos

	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get update'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install -y --allow-unauthenticated mendel-keyring'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get update'
	$(LOG) rootfs patch keyring finished

	$(LOG) rootfs patch bsp
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install --allow-downgrades --no-install-recommends -y $(PRE_INSTALL_PACKAGES)'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get upgrade -y'
	$(LOG) rootfs patch bsp finished

	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get clean'
	sudo chroot $(ROOTFS_DIR) bash -c 'pip3 install $(PIP_PACKAGES_EXTRA)'

# TODO(jtgans): Remove these when rapture is updated. Until then keeping the local repo
# is the only way of installing locally built packages on device.
# ifeq ($(FETCH_PACKAGES),false)
# 	sudo rm -f $(ROOTFS_DIR)/etc/apt/sources.list.d/local.list
# 	sudo rm -rf $(ROOTFS_DIR)/opt/aiy
# endif

	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo rm -f $(ROOTFS_DIR)/usr/bin/qemu-$(QEMU_ARCH)-static
	sudo umount $(ROOTFS_DIR)/dev
	sudo umount $(ROOTFS_DIR)/boot
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_PATCHED_IMG).wip
	sudo chown ${USER} $(ROOTFS_PATCHED_IMG).wip
	mv $(ROOTFS_PATCHED_IMG).wip $(ROOTFS_PATCHED_IMG)
	$(LOG) rootfs patch finished

$(ROOTFS_IMG): $(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG)
	$(LOG) rootfs img2simg
	$(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG) $(ROOTFS_IMG)
	$(LOG) rootfs img2simg finished

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_PATCHED_IMG) $(ROOTFS_RAW_IMG) $(ROOTFS_IMG)

targets::
	@echo "rootfs - runs multistrap to build the rootfs tree"

.PHONY:: rootfs rootfs_raw adjustments fetch_debs push_debs
