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

boot: $(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img

$(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img: | out-dirs
	$(LOG) boot fallocate
	fallocate -l $(BOOT_SIZE_MB)M $@
	mkfs.ext2 -F $@
	$(LOG) boot finished

targets::
	@echo "boot - builds the kernel and boot partition"

clean::
	rm -f $(PRODUCT_OUT)/boot_*.img

.PHONY:: boot
