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

# Preamble. Don't define any targets in this file! This is effectively just a
# common header where useful global vars go.

LOG := @$(ROOTDIR)/build/log.sh

RELEASE_NAME ?= unstable
ifneq ($(IS_JENKINS),)
  IS_EXTERNAL = true
  FETCH_PACKAGES = true
endif

ifeq (,$(wildcard /etc/dpkg/origins/glinux))
ifeq (,$(wildcard /google))
  IS_EXTERNAL ?= true
endif
endif

-include $(ROOTDIR)/board/arch.mk
BOARD_NAME ?= mendel

ifeq ($(IS_EXTERNAL),)
  CACHED_BUILD_IMAGE_DIRECTORY ?= /google/data/ro/teams/spacepark/mendel/kokoro/prod
  PREBUILT_DOCKER_ROOT ?= $(CACHED_BUILD_IMAGE_DIRECTORY)/docker/
  FETCH_PBUILDER_DIRECTORY ?= $(CACHED_BUILD_IMAGE_DIRECTORY)/pbuilder/
endif

FETCH_PACKAGES ?= false
USERSPACE_ARCH ?= arm64

# Architecture specific defines here
ifeq (armhf,$(USERSPACE_ARCH))
	QEMU_ARCH := arm
endif

ifeq (arm64,$(USERSPACE_ARCH))
	QEMU_ARCH := aarch64
endif

PACKAGES_EXTRA := \
	alsa-utils \
	apt-transport-https \
	apt-listchanges \
	apt-utils \
	aptitude \
	avahi-daemon \
	bash-completion \
	build-essential \
	cpio \
	cron \
	curl \
	dbus \
	debconf-i18n \
	debian-archive-keyring \
	debian-faq \
	dialog \
	dmidecode \
	dnsmasq \
	doc-debian \
	ethtool \
	file \
	gettext-base \
	git \
	gnupg \
	hdparm \
	i2c-tools \
	ifupdown \
	init \
	iptables \
	iputils-ping \
	isc-dhcp-client \
	isc-dhcp-common \
	kbd \
	krb5-locales \
	less \
	libc++1 \
	libc++abi1 \
	libclass-isa-perl \
	libinput10 \
	liblockfile-bin \
	libnss-mdns \
	libpam-systemd \
	libswitch-perl \
	libwayland-cursor0 \
	libwayland-egl1-mesa \
	libxcb-composite0 \
	libxcb-shape0 \
	libxcursor1 \
	libxkbcommon0 \
	linux-base \
	lm-sensors \
	locales \
	logrotate \
	lrzsz \
	lsof \
	man-db \
	manpages \
	nano \
	ncurses-term \
	net-tools \
	netbase \
	netcat-traditional \
	network-manager \
	openssh-server \
	parted \
	pciutils \
	psmisc \
	pulseaudio \
	python \
	python-minimal \
	python2.7 \
	python3-gst-1.0 \
	python3-jwt \
	python3-numpy \
	python3-pip \
	python3-protobuf \
	python3-reportbug \
	python3-setuptools \
	python3-wheel \
	reportbug \
	rsync \
	rsyslog \
	software-properties-common \
	sudo \
	systemd \
	systemd-sysv \
	tasksel \
	telnet \
	traceroute \
	unattended-upgrades \
	unzip \
	v4l-utils \
	vim \
	wamerican \
	wget \
	whiptail \
	wireless-tools \
	wpasupplicant \
	xdg-user-dirs \
	xwayland

PACKAGES_EXTRA += $(BOARD_PACKAGES_EXTRA)

PIP_PACKAGES_EXTRA := \
	python-periphery

PIP_PACKAGES_EXTRA += $(BOARD_PIP_PACKAGES_EXTRA)
