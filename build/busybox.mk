# Copyright 2019 Google LLC
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

BUSYBOX_WORK_DIR := $(PRODUCT_OUT)/obj/busybox

busybox: $(PRODUCT_OUT)/busybox
$(PRODUCT_OUT)/busybox:
	mkdir -p $(BUSYBOX_WORK_DIR)
	+make -C $(ROOTDIR)/tools/busybox O=$(BUSYBOX_WORK_DIR) mendel_defconfig
	+make -C $(ROOTDIR)/tools/busybox O=$(BUSYBOX_WORK_DIR)
	cp $(BUSYBOX_WORK_DIR)/busybox $(PRODUCT_OUT)/busybox

targets::
	@echo "busybox - embedded swiss-army knife"

clean::
	rm -rf $(BUSYBOX_WORK_DIR)
	rm -rf $(PRODUCT_OUT)/busybox

.PHONY:: busybox
