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

DATESTAMP       := $(shell TZ='UTC' date +%Y%m%d%H%M%S)
DISTDIR         := $(PRODUCT_OUT)/dist
DIST_BASENAME   := enterprise-$(RELEASE_NAME)-$(DATESTAMP)
DIST_ZIPNAME    := $(DISTDIR)/$(DIST_BASENAME).zip
DIST_SHA256NAME := $(DISTDIR)/$(DIST_BASENAME).sha256
DIST_SD_BASENAME:= enterprise-$(RELEASE_NAME)-flashcard-$(DATESTAMP)
DIST_SD_ZIPNAME := $(DISTDIR)/$(DIST_SD_BASENAME).zip
DIST_SD_SHA256NAME := $(DISTDIR)/$(DIST_SD_BASENAME).sha256

DIST_FILES      := \
	$(PRODUCT_OUT)/boot_arm64.img \
	$(PRODUCT_OUT)/home.img \
	$(PRODUCT_OUT)/partition-table-64gb.img \
	$(PRODUCT_OUT)/partition-table-16gb.img \
	$(PRODUCT_OUT)/partition-table-8gb.img \
	$(PRODUCT_OUT)/recovery.img \
	$(PRODUCT_OUT)/rootfs_arm64.img \
	$(PRODUCT_OUT)/u-boot.imx \
	$(ROOTDIR)/board/flash.sh \
	$(ROOTDIR)/board/README

DIST_SD_FILES   := \
	$(PRODUCT_OUT)/flashcard_arm64.img

package-images: $(DIST_ZIPNAME)
sign-images: $(DIST_SHA256NAME)
package-sd-image: $(DIST_SD_ZIPNAME)
sign-sd-image: $(DIST_SD_SHA256NAME)

dirs:
	mkdir -p $(PRODUCT_OUT)/obj/DIST
	mkdir -p $(PRODUCT_OUT)/obj/DIST/$(DIST_BASENAME)
	mkdir -p $(PRODUCT_OUT)/obj/DIST/$(DIST_SD_BASENAME)
	mkdir -p $(DISTDIR)

$(DIST_ZIPNAME): $(DIST_FILES) dirs
	cp $(DIST_FILES) $(PRODUCT_OUT)/obj/DIST/$(DIST_BASENAME)
	pushd $(PRODUCT_OUT)/obj/DIST; zip -9r $(DIST_ZIPNAME) $(DIST_BASENAME); popd

$(DIST_SHA256NAME): $(DIST_ZIPNAME) | dirs
	sha256sum $(DIST_ZIPNAME) > $(DIST_SHA256NAME)

$(DIST_SD_ZIPNAME): $(DIST_SD_FILES) dirs
	cp $(DIST_SD_FILES) $(PRODUCT_OUT)/obj/DIST/$(DIST_SD_BASENAME)
	pushd $(PRODUCT_OUT)/obj/DIST; zip -9r $(DIST_SD_ZIPNAME) $(DIST_SD_BASENAME); popd

$(DIST_SD_SHA256NAME): $(DIST_SD_ZIPNAME) | dirs
	sha256sum $(DIST_SD_ZIPNAME) > $(DIST_SD_SHA256NAME)

.PHONY:: package-images sign-images package-sd-image sign-sd-image dirs
