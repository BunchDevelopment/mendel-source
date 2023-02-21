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

bootloader: $(PRODUCT_OUT)/u-boot.imx
mkimage: $(HOST_OUT)/bin/mkimage

fetch-uboot:
	$(LOG) u-boot fetch
	wget -P $(PRODUCT_OUT)/packages \
		-e robots=off -nv -A deb -r -np -nd \
		https://mendel-linux.org/apt/$(RELEASE_NAME)-bsp-enterprise/pool/main/u/uboot-imx/
	$(LOG) u-boot fetch finished

ifeq ($(IS_JENKINS),)
$(PRODUCT_OUT)/u-boot.imx: uboot-imx | out-dirs
else
$(PRODUCT_OUT)/u-boot.imx: fetch-uboot | out-dirs
endif
	$(LOG) u-boot extract
	find $(PRODUCT_OUT)/packages -name 'uboot-imx*$(USERSPACE_ARCH)*.deb' | \
	sort -n | tail -1 | xargs \
	dpkg --fsys-tarfile | \
	tar --strip-components 2 -C $(PRODUCT_OUT) -xf - ./boot/u-boot.imx
	$(LOG) u-boot finished

ifeq ($(IS_JENKINS),)
$(HOST_OUT)/bin/mkimage: uboot-imx | out-dirs
else
$(HOST_OUT)/bin/mkimage: fetch-uboot | out-dirs
endif
	mkdir -p $(HOST_OUT)/bin
	find $(PRODUCT_OUT)/packages -name 'uboot-mkimage*.deb' | \
	sort -n | tail -1 | xargs \
	dpkg --fsys-tarfile | \
	tar --strip-components 3 -C $(HOST_OUT)/bin -xf - ./usr/bin/mkimage

.PHONY:: bootloader mkimage fetch-uboot
