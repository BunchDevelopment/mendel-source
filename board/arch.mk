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

ifeq ($(IS_EXTERNAL),)
  ROOTFS_RAW_CACHE_DIRECTORY ?= /google/data/ro/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise/rootfs/latest/
endif

BOARD_PACKAGES_EXTRA :=

BOOT_SIZE_MB := 128
HOME_SIZE_MB := 2048
ROOTFS_SIZE_MB := 4096

BOARD_NAME := enterprise
