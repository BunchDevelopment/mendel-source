# Board Definitions and Targeting Mendel for Other Boards

Board control and BSP generation are handled primarily by two things: the board
manifest file used by repo to check out the source tree, and also the board/
repository at the root of the tree.

## Board Manifest Files

In general, each XML file in the manifest refers to each board configuration
that Mendel supports, and each is named by the board's codename. The most common
is the Coral EdgeTPU Dev Board, or "enterprise", which is denoted by the
`enterprise.xml` file.

Mendel's core packages are defined in another file called `mendel.xml`. This
includes the definition of the remotes, the main branch, documentation, tools,
and packages that are required to make Mendel, well, Mendel.

Each board XML file is expected to `<include name="mendel.xml"/>` at the top of
the `<manifest>` node, and then provide additional packages that need to be
brought down to build for the targeted board. At minimum, this XML file must
include the following repositories:

  - A `board/` project
  - The Linux kernel
  - The bootloader (typically u-boot or some other bootloader like LK)

Other board-specific repositories may be included, including tools and packages.
The typical idea is to make sure that sources are installed at the root of the
tree in the same directory name as the Debian package for them under the
`packages/` directory. For example, the `enterprise.xml` board manifest checks
out the Linux kernel in the `linux-imx` directory at the root of the tree, and
then checks out the Debian package tree for it in `packages/linux-imx`.

## The `board/` Repository

This repository consists of a tree with _at least_ the following files:

  - flash.sh
  - boot.mk
  - partition-table.mk
  - bootloader.mk
  - packages.mk
  - arch.mk

Optional files that are included if present:

  - sdcard.mk
  - flashcard.mk
  - recovery.mk

#### `arch.mk`
This makefile defines the `BOARD_NAME`, `BOARD_PACKAGES_EXTRA`, and any other
make variables that might be necessary early on in the build.

`BOARD_NAME` is required and defines the codename for the board. This is used
for the BSP repository name that is generated using `apt-ftparchive`.

`BOARD_PACKAGES_EXTRA` defines any extra packages that this board definition may
require to be installed in the root filesystem from the upstream Debian
repositories. Generally this can remain unset and it is recommended to use
package dependencies rather than using this variable to install packages that
may be needed.

#### `packages.mk`
This makefile uses the `make-pbuilder-bsp-package-target` macro to define
board support packages that are required for the board to function. This must at
minimum define packages for the bootloader, the kernel, and a meta package that
depends on other packages.

In the `enterprise` case, this defines `linux-imx`, `uboot-imx`, and
`meta-enterprise`. The `meta-enterprise` package is an empty package that has a
`Depends:` line in the `control` file that brings in everything necessary to
make the board work on first boot.

#### `flash.sh`
This script flashes a connected board with the various filesystem images
generated during the build. At minimum this typically must be the rootfs and
the bootloader.

#### `boot.mk`
This makefile defines a target called `boot` that builds the bootloader
filesystem image -- not the actual bootloader. Typically this results in a
bootloader image called `$(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img`.

#### `partition-table.mk`
This makefile provides a target called `partition-table` that builds the
partition map for the board. Typically this produces
`$(PRODUCT_OUT)/partition-table.img`.

#### `bootloader.mk`
This makefile script provides a target called `bootloader` that actually builds
the bootloader.

*Note*: in the `enterprise` case, we build the bootloader as a Debian package so
that it may be upgraded at runtime without requiring a full reflash of the
board. This target, in this case, extracts the `u-boot.imx` file from the
package so that we may flash it to the pseudo-partition `bootloader0` at flash
time. Not all boards may need this behavior.

#### `sdcard.mk`
This makefile produces an alternative filesystem image suitable for flashing to
an sdcard by providing an `sdcard` target that does all the work. For a normal
build, this is not required to be present.

#### `flashcard.mk`
This makefile produces a filesystem similar to the `sdcard` target that is
suitable to flash to an SD card and boot from, except this actually flashes the
emmc on boot. The target name expected is `flashcard`.

## Targeting a New Board for Mendel Linux

Generally this process can be broken down into the following steps. In this
example, we'll use a board called `frodo`:

  1. Create a new, empty board repository called `board-frodo`
  2. Create a new manifest file for the target board called `frodo.xml`:

        <?xml version="1.0" encoding="UTF-8"?>
        <manifest>
          <include name="mendel.xml"/>

          <project name="board-frodo" path="board" />

          <!-- uboot bootloader -->
          <project name="uboot-frodo" path="uboot" />
          <project name="uboot-frodo-debian" path="packages/uboot" />

          <!-- kernel -->
          <project name="linux-frodo" path="linux" />
          <project name="linux-frodo-debian" path="packages/linux" />

          <!-- meta package -->
          <project name="meta-frodo" path="packages/meta-frodo" />

          <!-- other packages... -->
        </manifest>

  3. Checkout the new repository using the `frodo.xml` manifest.
  4. Go into `board/` and define the following files:

     - `boot.mk`
     - `partition-table.mk`
     - `bootloader.mk`
     - `packages.mk`
     - `arch.mk`

  5. `source build/setup.sh && m` to test.
