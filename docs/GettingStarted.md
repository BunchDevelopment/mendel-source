# Getting Started with Mendel Linux

## Prerequisites

## Check out the repository

We've stored our code in Gerrit, and like the Android developers before us, we
use `repo` to manage the projects in our Gerrit repositories.

To get started, first make sure you have a Git login for all our projects
by going to [googlesource.com/new-password](https://www.googlesource.com/new-password)
and pasting the provided script into a terminal.

Now you need to pull down a copy of the `repo`
tool from our public facing sites and add it to your path:

```
mkdir -p bin
export PATH=$PATH:$HOME/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

Make sure you've initialized git with your name and email address, and have
configured it properly for fetching the sources:

```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Once you've done this, you're actually ready to check out the sources. Make a
new directory where you'd like it to live, and initialize `repo` with the
current release branch.

The board you target determines which manifest you need to init. Each XML file is
named after the board's codename. A current list of boards that are supported is
available in the [manifest project](https://coral.googlesource.com/manifest/+/refs/heads/master),
listed by codename. To target a non-default manifest, add the `-m` flag to
`repo init` with the name of the manifest XML file.

For example ,for the Dev Board you use the default:

```
repo init -u https://coral.googlesource.com/manifest
```

whereas for the Coral Dev Board Mini, you need to use the following manifest:

```
repo init -u https://coral.googlesource.com/manifest -m excelsior.xml
```

Note that some boards require specific groups to be enabled to pull down the
correct packages. Contact the authors for more information on what groups are
needed for your specific board and situation.


After initializing the repo, you can check out the sources with

```
repo sync -j$(nproc)
```

After a short wait, you'll be ready to go for making changes to the repository
and building images.

## Prepare your build environment

To build Mendel Linux from source, you will need at least the following:

  - A 64-bit CPU
  - Kernel 4.15 or newer
  - binfmt-support 2.1.7 or newer

### Operating Systems

Currently the Mendel Linux build system assumes that you are building on a
Debian-based system that uses `apt-get` as the primary packaging tool. Building
on other platforms may be possible, but is currently unsupported.

At the moment, we suggest using Ubuntu 18.10+ or Debian Buster or newer.

Building *can* be done on Ubuntu 18.04, but you will need to run the included
`build/fix_aarch64_binfmt.sh` script to fix a problem with the qemu-user-static
package.

### qemu-user-static

Since Mendel is designed to be run on an ARM CPU core, there are occasionally
times where we can't build things using a cross compiler and instead have to
emulate the target architecture for a "native" build. To accomplish this, Mendel
makes heavy use of the `qemu-user-static` system emulator to allow the host
Linux kernel to run ARM binaries. To install it, simply do this:

```
$ sudo apt-get install qemu-user-static
```

### Docker

Further, to isolate the build from the host system, we build our packages using
pbuilder inside of Docker. We recommend configuring Docker so that the user that
you normally use can use it. You can find out how to install Docker on your
machine by following [Docker's official installation instructions for Docker
CE](https://docs.docker.com/install/) or, on some variations of Debian and
Ubuntu, the following will suffice:

```
$ sudo apt-get install docker.io
$ sudo adduser $USER docker
```

Once that's complete, you'll want to logout and login to ensure you're in the
`docker` group.

### Fastboot

Mendel boards typically use the `fastboot` protocol for flashing boards, much
like an Android device. Once you've built, you will need to install `fastboot`
either via the [Android SDK
Manager](https://developer.android.com/studio/#downloads) or through your
operating system's package manager.

Once you have `fastboot` installed, you'll want to go sudo-less to flash your
device by making a new udev rules file:

```
sudo sh -c "echo 'SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0525\", MODE=\"0664\", \
GROUP=\"plugdev\", TAG+=\"uaccess\"' >> /etc/udev/rules.d/65-android-local.rules"
sudo udevadm control --reload-rules && udevadm trigger
```

In some rare cases, it you may need a reboot to ensure udev is appropriately
reloaded with the new rule. Now you can check that you can use `fastboot` without
root privileges by running the following with a fastboot-compatible device
connected:

```
fastboot devices
```

If you see output from the tool, you know it's working fine.

## Build the tree

To build the tree, first you need to prepare your environment by installing some
basic packages on your host. You can install them by doing the following:

```
apt-get install build-essential qemu-user-static bc
```

Once that's done (you should only ever need to do this once) you can setup your
environment by running this:

```
source build/setup.sh
```

At this point you'll have a couple of extra functions available to navigate
around the tree and build things in part or in whole. See below for more
information, or simply [read the source
here](https://coral.googlesource.com/build/+/refs/heads/master/setup.sh).

Now you can build the tree by running:

```
m
```

The first time you'll be asked to set a pbuilder mirror site. Use
http://deb.debian.org/debian.

If you have not modified any packages, and would like to speed up your build,
specify `FETCH_PACKAGES=true` like this:

```
FETCH_PACKAGES=true m
```

This will cause packages to be fetched from the upstream Mendel APT repositories
instead of building them locally.

## Artifact caching

There are a few build artifacts that generally don't change, and can be cached
to provide a build speedup.

#### cache/base.tgz
Filesystem tarball for pbuilder. Set `FETCH_PBUILDER_DIRECTORY` in your
environment to the folder containing a copy of the file to use an already built
version.

#### rootdir_ARCH.raw.img
Base filesystem tarball made by multistrap. Set `ROOTFS_RAW_CACHE_DIRECTORY` in
your environment to the folder containing a copy of the file to use an already
built version.

#### cache/aiy-board-builder.tar
Docker container that the build happens in. Set `PREBUILT_DOCKER_ROOT` in your
environment to the folder containing a copy of the file to use an already built
version.

## Flash a device

After the above is complete, you should be able to flash the device:

```
flash.sh
```

To build the world for an sdcard, build the `sdcard` target:

```
m docker-sdcard
```

If the device was flashed properly you should be able to login to it:

```
mdt shell
```

## Quick Explanation of the Build System

The build system is relatively straightforward. It's a selection of split
out multi-target makefiles defined in the `build/` directory.

Adding modules is also relatively straightforward, assuming a decent
understanding of GNU Make rules. An example of how to get started is available
in the `build/template.mk` script. Simply copy this file to a new filename, and
then add the following line to the list of includes in the toplevel
`build/Makefile` file:

```
include $(ROOTDIR)/build/your-module.mk
```

Note that `targets` and `clean` are special partial targets. The rules must be
defined with a double colon (`::`) and not added to your module's `.PHONY`
target. Additionally, the output of the `targets` command is a list of strings
of the form:

```
targetname - some short description of your target
```

## Quick Tour of setup.sh Functions

### m -- Make everything from the toplevel

The `m` function can be called from any directory in the filesystem to build the
entire tree from the ground up. You can specify a target to build with the
command as well, just like you would do with make.

Effectively the command does a pushd to the root of the tree and issues a make
command. You can specify any options or targets you'd like to build, including
the `targets` command to have a look around in the build system.

### j -- Jump around the directory tree

This is a kind of switchboard of sorts that lets you jump around the tree
quickly. Many of the paths are arcane because of historical reasons, so this
tool was written to make things a bit easier.

If you issue the `j` command with no arguments, it will automatically change
your current working directory to the root of the tree. If, however, you issue
`j help`, it will list a list of target names you can "jump" to. You can open up
`build/setup.sh` to see which ones are currently defined, or just jump around
and explore.

## Quick Tour of the Directory Layout

#### build/
Contains build scripts, the setup.sh script and rootfs overlay, as well as some
additional tooling.

#### board/
Contains build scripts to modify the behavior of the build system for the
specific board you have checked out from source. Essentially, these scripts
compile the bootloader and kernel, setup the partition map, fstab, flash script
and also provide the build definitions for the BSP packages.

See also [BoardDefinitions.md](BoardDefinitions.md)

#### cache/
Contains the debootstrap tarball you must build before starting any other build
lives here. This directory is ephemeral and doesn't exist on a first clone, but
will also not be removed when the `clean` target is run. Bear in mind: if you
update the package list in `build/debootstrap.mk`, you'll need to re-reun `mm
deboostrap make-debootstrap-tarball` to regenerate this.

#### docs/
Contains this documentation, as well as other documentation about the build
system and working in the tree.

#### imx-firmware/
Contains the atheros and qualcomm Wifi firmware blobs. Cloned from the
AndroidThings repository and will likely migrate out as time goes on and bom
selections change.

#### linux-imx/
Contains the source code for the Linux kernel.

#### out/
The ephemeral directory that contains both local host binaries and tools, as
well as build artifacts and the final images produced. It has a specific
structure documented elsewhere.

#### packages/
Debian package sources used to build the packages installed to make the
distribution more functional for the Enterprise board.

#### tools/
Contains miscellaneous tools to support the image. Bpt and img2simg are forked
from the Android Things tree, and imx-mkimage from NXP.

#### uboot-imx/
Contains the u-boot bootloader, with support for i.MX8 devices.
