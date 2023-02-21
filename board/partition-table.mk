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

BPTTOOL := $(ROOTDIR)/tools/bpt/bpttool
MMC_8GB  := 7818182656
MMC_16GB := 15634268160
MMC_64GB := 62537072640

SOURCE_JSON := $(ROOTDIR)/board/partition-table.json
TARGET_8GB_JSON  := $(PRODUCT_OUT)/partition-table-8gb.json
TARGET_8GB_IMG   := $(PRODUCT_OUT)/partition-table-8gb.img
TARGET_16GB_JSON := $(PRODUCT_OUT)/partition-table-16gb.json
TARGET_16GB_IMG  := $(PRODUCT_OUT)/partition-table-16gb.img
TARGET_64GB_JSON := $(PRODUCT_OUT)/partition-table-64gb.json
TARGET_64GB_IMG  := $(PRODUCT_OUT)/partition-table-64gb.img

partition-table: \
  $(TARGET_8GB_JSON) $(TARGET_8GB_IMG) \
  $(TARGET_16GB_JSON) $(TARGET_16GB_IMG) \
  $(TARGET_64GB_JSON) $(TARGET_64GB_IMG)

# 8GB
$(TARGET_8GB_JSON): $(SOURCE_JSON)
$(TARGET_8GB_JSON): MMC_SIZE = $(MMC_8GB)
$(TARGET_8GB_IMG): $(SOURCE_JSON)
$(TARGET_8GB_IMG): MMC_SIZE = $(MMC_8GB)

# 16GB
$(TARGET_16GB_JSON): $(SOURCE_JSON)
$(TARGET_16GB_JSON): MMC_SIZE = $(MMC_16GB)
$(TARGET_16GB_IMG): $(SOURCE_JSON)
$(TARGET_16GB_IMG): MMC_SIZE = $(MMC_16GB)

# 64GB
$(TARGET_64GB_JSON): $(SOURCE_JSON)
$(TARGET_64GB_JSON): MMC_SIZE = $(MMC_64GB)
$(TARGET_64GB_IMG): $(SOURCE_JSON)
$(TARGET_64GB_IMG): MMC_SIZE = $(MMC_64GB)

$(PRODUCT_OUT)/partition-table-%.json: $(SOURCE_JSON)
	mkdir -p $(@D)
	$(BPTTOOL) make_table --disk_size $(MMC_SIZE) --input $< --output_json $@

$(PRODUCT_OUT)/partition-table-%.img: $(SOURCE_JSON)
	mkdir -p $(@D)
	$(BPTTOOL) make_table --disk_size $(MMC_SIZE) --input $< --output_gpt $@

targets::
	@echo "partition-table - builds partition table images for all eMMC sizes"

clean::
	rm -f $(PRODUCT_OUT)/partition-table-*.json
	rm -f $(PRODUCT_OUT)/partition-table-*.img

.PHONY:: partition-table
