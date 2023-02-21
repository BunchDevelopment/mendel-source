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

recovery: $(PRODUCT_OUT)/recovery.img
recovery-xz: $(PRODUCT_OUT)/recovery.img.xz

recovery-allocate: | out-dirs
	fallocate -l 4M $(PRODUCT_OUT)/recovery.img

$(PRODUCT_OUT)/recovery.img: recovery-allocate \
                           $(ROOTDIR)/board/bootloader.mk \
                           | $(PRODUCT_OUT)/u-boot.imx
	dd if=$(PRODUCT_OUT)/u-boot.imx of=$(PRODUCT_OUT)/recovery.img conv=notrunc seek=$(UBOOT_START) bs=512

$(PRODUCT_OUT)/recovery.img.xz: $(PRODUCT_OUT)/recovery.img
	xz -k -T0 -0 $(PRODUCT_OUT)/recovery.img

targets::
	@echo "recovery     - generate a flashable recovery image"

clean::
	rm -f $(PRODUCT_OUT)/recovery.img

.PHONY:: recovery recovery-xz
