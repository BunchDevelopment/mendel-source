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

ifneq ($(HOME_SIZE_MB),)
HOME_DIR := $(PRODUCT_OUT)/obj/HOME
HOME_RAW_IMG := $(PRODUCT_OUT)/obj/HOME/home.raw.img
HOME_IMG := $(PRODUCT_OUT)/home.img
endif

$(HOME_DIR):
	mkdir -p $(HOME_DIR)

home: $(HOME_IMG)
	$(LOG) home finished

home_raw: $(HOME_RAW_IMG)

$(HOME_RAW_IMG): $(HOME_DIR)
	$(LOG) home raw-build
ifneq ($(HOME_SIZE_MB),)
	fallocate -l $(HOME_SIZE_MB)M $(HOME_RAW_IMG)
	mkfs.ext4 -F -j $(HOME_RAW_IMG)
endif
	$(LOG) home raw-build finished

$(HOME_IMG): $(HOST_OUT)/bin/img2simg $(HOME_RAW_IMG)
	$(LOG) home img2simg
ifneq ($(HOME_SIZE_MB),)
	$(HOST_OUT)/bin/img2simg $(HOME_RAW_IMG) $(HOME_IMG)
endif
	$(LOG) rootfs img2simg finished

clean::
	rm -rf $(HOME_RAW_IMG) $(HOME_IMG) $(HOME_DIR)

targets::
	@echo "home - creates the home partition image"

.PHONY:: home home_raw
