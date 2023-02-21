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

REQUIRED_PACKAGES := \
	apt-transport-https \
	apt-utils \
	bc \
	binfmt-support \
	binutils-aarch64-linux-gnu \
	build-essential \
	ca-certificates \
	cdbs \
	coreutils \
	cpio \
	crossbuild-essential-arm64 \
	crossbuild-essential-armhf \
	curl \
	debhelper \
	debian-archive-keyring \
	device-tree-compiler \
	dh-python \
	fakeroot \
	gdisk \
	genext2fs \
	git \
	gnome-pkg-tools \
	kpartx \
	libcap-dev \
	libwayland-dev \
	mtools \
	multistrap \
	parted \
	pbuilder \
	pkg-config \
	python-minimal \
	python2.7 \
	python3 \
	python3-all \
	python3-apt \
	python3-debian \
	python3-git \
	python3-setuptools \
	qemu-user-static \
	quilt \
	rsync \
	xz-utils \
	wget \
	zip \
	zlib1g-dev

prereqs:
	sudo apt-get update
	sudo apt-get install --no-install-recommends -y $(REQUIRED_PACKAGES)

	# Hack in known-to-be-working-in-docker version, see
	# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=930684
	wget -O debbootstrap.deb http://ftp.us.debian.org/debian/pool/main/d/debootstrap/debootstrap_1.0.89_all.deb
	sudo dpkg -i debbootstrap.deb

targets::
	@echo "prereqs    - installs packages required by this Makefile"

.PHONY:: prereqs
