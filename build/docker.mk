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

docker-build: $(ROOTDIR)/cache/aiy-board-builder.tar
ifneq ($(PREBUILT_DOCKER_ROOT),)
$(ROOTDIR)/cache/aiy-board-builder.tar: $(PREBUILT_DOCKER_ROOT)/aiy-board-builder.tar
	mkdir -p $(ROOTDIR)/cache
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/aiy-board-builder.tar: $(ROOTDIR)/build/Dockerfile $(ROOTDIR)/build/prereqs.mk
	mkdir -p $(ROOTDIR)/cache/docker-build
	cp -a $(ROOTDIR)/build $(ROOTDIR)/cache/docker-build
	cp -a $(ROOTDIR)/board $(ROOTDIR)/cache/docker-build
	cp -a $(ROOTDIR)/build/Dockerfile $(ROOTDIR)/cache/docker-build
	docker build -t aiy-board-builder $(ROOTDIR)/cache/docker-build
	docker image save -o $@ aiy-board-builder:latest
	docker rmi aiy-board-builder:latest
	rm -rf $(ROOTDIR)/cache/docker-build
endif

DOCKER_VOLUMES := \
  -v /dev\:/dev \
  -v $(ROOTDIR)\:/rootdir

DOCKER_ENV := \
  -e "FETCH_PACKAGES=$(FETCH_PACKAGES)" \
  -e "HEADLESS_BUILD=$(HEADLESS_BUILD)" \
  -e "IS_JENKINS=$(IS_JENKINS)" \
  -e "IS_EXTERNAL=$(IS_EXTERNAL)" \
  -e "RELEASE_NAME=$(RELEASE_NAME)" \
  -e "http_proxy=$(http_proxy)" \
  -e "USERSPACE_ARCH=$(USERSPACE_ARCH)" \
  -e "QEMU_ARCH=$(QEMU_ARCH)"

DOCKER_FLAGS := \
  --rm --privileged --tty

ifneq ($(ROOTFS_RAW_CACHE_DIRECTORY),)
  DOCKER_VOLUMES += -v $(ROOTFS_RAW_CACHE_DIRECTORY)\:/rootfs
  DOCKER_ENV += -e "ROOTFS_RAW_CACHE_DIRECTORY=/rootfs"
endif

ifneq ($(FETCH_PBUILDER_DIRECTORY),)
	DOCKER_VOLUMES += -v $(FETCH_PBUILDER_DIRECTORY)\:/pbuilder
	DOCKER_ENV += -e "FETCH_PBUILDER_DIRECTORY=/pbuilder"
endif

INTERACTIVE:=$(shell [[ -t 0 ]] && echo true)
ifeq ($(INTERACTIVE),true)
  DOCKER_FLAGS += -i
endif

# Runs any make TARGET in x86 docker image ('m docker-TARGET')
docker-%: docker-build;
	docker load -i $(ROOTDIR)/cache/aiy-board-builder.tar
	docker run \
		$(DOCKER_FLAGS) \
		$(DOCKER_VOLUMES) \
		$(DOCKER_ENV) \
		-w /rootdir \
		aiy-board-builder \
		/bin/bash -c \
			'groupadd --gid $(shell id -g) $(shell id -g -n); \
			useradd -m -e "" -s /bin/bash --gid $(shell id -g) --uid $(shell id -u) $(shell id -u -n); \
			passwd -d $(shell id -u -n); \
			echo "$(shell id -u -n) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
			sudo cp /rootdir/build/99network-settings /etc/apt/apt.conf.d/; \
			sudo chmod 644 /etc/apt/apt.conf.d/99network-settings; \
			sudo -E -u $(shell id -u -n) /bin/bash -c "source build/setup.sh; m \
			-j$$(nproc) $*";'

# Test x86 docker ('m docker-test-docker')
test-docker:
	@echo "Docker architecture: $(shell uname -a)"
	@echo "Compiler version: $(shell gcc --version)"
	@echo -e '#include <stdio.h>\nint main() {printf("\\nHello Docker gcc test\\n\\n");\n return 0;\n}' > hello.c
	@make hello
	@./hello
	@rm -f hello.c hello

# Open a docker shell ('m docker-debug-shell')
debug-shell:
	bash

.DEFAULT_GOAL:=docker-all
.MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

.PHONY:: docker-build
