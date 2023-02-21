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

pbuilder-base: $(ROOTDIR)/cache/cross-base.tgz $(ROOTDIR)/cache/$(USERSPACE_ARCH)-base.tgz

ifneq ($(FETCH_PBUILDER_DIRECTORY),)
$(ROOTDIR)/cache/cross-base.tgz: $(FETCH_PBUILDER_DIRECTORY)/cross-base.tgz | out-dirs
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/cross-base.tgz:
	mkdir -p $(ROOTDIR)/cache
	sudo pbuilder create \
		--basetgz $@ \
		--distribution buster \
		--architecture amd64 \
		--extrapackages "crossbuild-essential-armhf crossbuild-essential-arm64 debhelper gnupg lintian qemu-user-static ca-certificates" \
		--aptcache ""
endif

ifneq ($(FETCH_PBUILDER_DIRECTORY),)
$(ROOTDIR)/cache/$(USERSPACE_ARCH)-base.tgz: $(FETCH_PBUILDER_DIRECTORY)/$(USERSPACE_ARCH)-base.tgz | out-dirs
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/$(USERSPACE_ARCH)-base.tgz: /usr/bin/qemu-$(QEMU_ARCH)-static
	mkdir -p $(ROOTDIR)/cache
	sudo pbuilder create \
		--basetgz $@ \
		--distribution buster \
		--architecture $(USERSPACE_ARCH) \
		--extrapackages "build-essential debhelper gnupg lintian ca-certificates" \
		--aptcache ""
	mkdir -p $(ROOTDIR)/cache/base-tmp
	cd $(ROOTDIR)/cache/base-tmp; \
	sudo tar xf $@; \
	sudo cp /usr/bin/qemu-$(QEMU_ARCH)-static usr/bin; \
	sudo tar cf base.tar .; \
	gzip base.tar; mv -f base.tar.gz $@
	sudo rm -rf $(ROOTDIR)/cache/base-tmp
endif

# $1 package name
define get-deb-version-orig
$(shell head -n1 $(ROOTDIR)/packages/$1/debian/changelog | awk '{split ($$2,a,"-"); print a[1]}' | tr -d '()')
endef

define get-deb-version-full
$(shell head -n1 $(ROOTDIR)/packages/$1/debian/changelog | awk '{print $$2}' | tr -d '()')
endef

# $1: package name
# $2: source location (relative to ROOTDIR)
# $3: space separated list of package dependencies (may be empty)
# $4: space separated list of external dependencies (may be empty)
# $5: dpkg-buildpackage --build value (may be empty, defaults to full)
# $6: repository which package belongs to (e.g. core or bsp)
# $7: whether to use a cross or native pbuilder env (may be empty, defaults to cross)
define make-pbuilder-package-target
$1: $(PRODUCT_OUT)/.$1-pbuilder-$(USERSPACE_ARCH)
PBUILDER_TARGETS += $(PRODUCT_OUT)/.$1-pbuilder-$(USERSPACE_ARCH)

# If we don't have the source for a package for some reason, don't panic.
# Just set the pbuilder stamp, and it will come from apt.
ifneq (,$(wildcard $(ROOTDIR)/packages/$1))
$(PRODUCT_OUT)/.$1-pbuilder-$(USERSPACE_ARCH): \
	$(foreach package,$3,$(PRODUCT_OUT)/.$(package)-pbuilder-$(USERSPACE_ARCH)) \
	$$(shell find $(ROOTDIR)/packages/$1 -type f) \
	$$(shell find $(ROOTDIR)/$2 -type f | sed -e 's/ /\\ /g') \
	| out-dirs $(ROOTDIR)/cache/$(if $7,$7,cross)-base.tgz \
	$4

	$(LOG) $1 pbuilder
	$(ROOTDIR)/build/update_packages.sh
	if [[ -e $(ROOTDIR)/$2/.git ]]; then \
		cd $(ROOTDIR)/$2; \
		git submodule init; \
		git submodule update; \
	fi
	rm -rf $(PRODUCT_OUT)/obj/$1
	mkdir -p $(PRODUCT_OUT)/obj/$1
	rsync -a --exclude .git/ $(ROOTDIR)/$2/* $(PRODUCT_OUT)/obj/$1
	cp -a $(ROOTDIR)/packages/$1/debian $(PRODUCT_OUT)/obj/$1
	touch -t 7001010000  $(PRODUCT_OUT)/obj/$1
	tar -C $(PRODUCT_OUT)/obj -I 'gzip -n' --exclude=debian/ -cf \
		$(PRODUCT_OUT)/obj/$1_$$(call get-deb-version-orig,$1).orig.tar.gz \
		$1
	tar -C $(PRODUCT_OUT)/obj/$1 -I 'gzip -n' -cf \
		$(PRODUCT_OUT)/obj/$1_$$(call get-deb-version-full,$1).debian.tar.gz \
		debian

	sudo cp $(ROOTDIR)/build/99network-settings ~/
	echo "cp ~/99network-settings /etc/apt/apt.conf.d/" | sudo tee ~/.pbuilderrc

	$(LOG) $1 pbuilder pdebuild
	cd $(PRODUCT_OUT)/obj/$1; pdebuild \
		--buildresult $(PRODUCT_OUT)/packages/$(if $6,$6,core) -- \
		--debbuildopts "--build=$(if $5,$5,full) -sa --check-command=lintian --check-option=--profile=mendel" \
		--basetgz $(ROOTDIR)/cache/$(if $7,$7,cross)-base.tgz \
		--configfile $(ROOTDIR)/build/pbuilderrc \
		--hookdir $(ROOTDIR)/build/pbuilder-hooks \
		--host-arch $(USERSPACE_ARCH) --logfile $(PRODUCT_OUT)/$1-$(USERSPACE_ARCH).log
	$(LOG) $1 finished
else
$(PRODUCT_OUT)/.$1-pbuilder-$(USERSPACE_ARCH): | out-dirs
endif
	touch $(PRODUCT_OUT)/.$1-pbuilder-$(USERSPACE_ARCH)

$1-source-directory:
	echo "Source directory: $2"

.PHONY:: $1 $1-source-directory
endef

# Convenience macro to target a package to the bsp repo
define make-pbuilder-bsp-package-target
$(call make-pbuilder-package-target,$1,$2,$3,$4,$5,bsp,$6)
endef

$(eval $(call make-pbuilder-package-target,android-core,android-core))
$(eval $(call make-pbuilder-package-target,mendel-minimal,packages/mendel-minimal))
$(eval $(call make-pbuilder-package-target,base-files,packages/base-files))
$(eval $(call make-pbuilder-package-target,edgetpuvision,packages/edgetpuvision,,,,,$(USERSPACE_ARCH)))
$(eval $(call make-pbuilder-package-target,edgetpudemo,packages/edgetpudemo))
$(eval $(call make-pbuilder-package-target,mdt-services,packages/mdt-services))
$(eval $(call make-pbuilder-package-target,mendel-distro-info-data,packages/mendel-distro-info-data))
$(eval $(call make-pbuilder-package-target,mendel-keyring,packages/mendel-keyring))
$(eval $(call make-pbuilder-package-target,runonce,packages/runonce))
$(eval $(call make-pbuilder-package-target,usb-gadget,packages/usb-gadget))
$(eval $(call make-pbuilder-package-target,vitalsd,packages/vitalsd,,,,,$(USERSPACE_ARCH)))
$(eval $(call make-pbuilder-package-target,meta-mendel,packages/meta-mendel))

include $(ROOTDIR)/board/packages.mk

ALL_PACKAGE_TARGETS := $(PBUILDER_TARGETS)
packages-tarball: $(ROOTDIR)/cache/packages.tgz
$(ROOTDIR)/cache/packages.tgz: $(ALL_PACKAGE_TARGETS) | out-dirs
	$(ROOTDIR)/build/update_packages.sh
	find $(PRODUCT_OUT)/packages -name '*.deb' -or -name 'Packages' | \
		sed -e "s#$(PRODUCT_OUT)/##g" | \
		tar -C $(PRODUCT_OUT) --overwrite -czf $@ -T -

$(PRODUCT_OUT)/mendel.list: $(ROOTDIR)/build/mendel.list.template
	sed -e "s;%BOARDNAME%;$(BOARD_NAME);g" $(ROOTDIR)/build/mendel.list.template > $(PRODUCT_OUT)/mendel.list

upstream-delta: $(ROOTDIR)/cache/update.tgz $(PRODUCT_OUT)/mendel.list
$(ROOTDIR)/cache/update.tgz:
	$(ROOTDIR)/build/generate_update_tarball.py -rootdir=$(ROOTDIR) -sources_list=$(PRODUCT_OUT)/mendel.list -package_dir=$(PRODUCT_OUT)/packages -output_tarball=$(ROOTDIR)/cache/update.tgz

packages:: $(ALL_PACKAGE_TARGETS)

.PHONY:: packages pbuilder-base upstream-delta upstream-tarball
