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

SHELL := $(shell which /bin/bash)
INSIDE_DOCKER := $(shell [[ -f /.dockerenv ]] && echo yes)
HAVE_QEMU := $(shell [[ -f /var/lib/binfmts/qemu-aarch64 ]] && echo yes)
HAVE_FIXATED_QEMU := $(shell [[ -f /var/lib/binfmts/qemu-aarch64 ]] && tail -n1 /var/lib/binfmts/qemu-aarch64)

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

ifeq ($(INSIDE_DOCKER),)
  ifeq ($(HAVE_QEMU),)
    $(error qemu-user-static is either not installed or not configured properly.)
  endif

  ifeq ($(HAVE_FIXATED_QEMU),)
    $(warning Your version of qemu-user-static is too old and does not support)
    $(warning fixated binaries. On Debian-based systems, you can run)
    $(warning `build/fix_aarch64_binfmts.sh` to update your system binfmts)
    $(warning to fixate the aarch64 interpreter in kernel space.)
    $(warning )
    $(warning NOTE: This will modify the global state of your system!)
    $(error Build cannot continue)
  endif
endif

include $(ROOTDIR)/build/preamble.mk

precheck:
	+make -f $(ROOTDIR)/build/Makefile validate-bootstrap-tarball
	+make -f $(ROOTDIR)/build/Makefile all

out-dirs:
	@mkdir -p $(PRODUCT_OUT)/packages/core
	@mkdir -p $(PRODUCT_OUT)/packages/bsp
	@mkdir -p $(PRODUCT_OUT)/obj
	@mkdir -p $(ROOTDIR)/cache

all: rootfs home bootloader partition-table

dist: package-images sign-images package-sd-image sign-sd-image

lintian: packages
	lintian $(PRODUCT_OUT)/packages/core/*.deb $(PRODUCT_OUT)/packages/bsp/*.deb

help: targets
targets::
	@echo "Targets available for building in this Makefile:"
	@echo

include $(ROOTDIR)/board/boot.mk
include $(ROOTDIR)/board/partition-table.mk

include $(ROOTDIR)/build/img2simg.mk
include $(ROOTDIR)/build/busybox.mk
include $(ROOTDIR)/build/prereqs.mk
include $(ROOTDIR)/build/home.mk
include $(ROOTDIR)/build/rootfs.mk
include $(ROOTDIR)/build/docker.mk
include $(ROOTDIR)/build/packages.mk
include $(ROOTDIR)/build/multistrap.mk

include $(ROOTDIR)/board/bootloader.mk
include $(ROOTDIR)/board/dist.mk
-include $(ROOTDIR)/board/sdcard.mk
-include $(ROOTDIR)/board/flashcard.mk
-include $(ROOTDIR)/board/recovery.mk

clean::
	rm -rf $(ROOTDIR)/out

.PHONY:: all help targets clean boot-targets
