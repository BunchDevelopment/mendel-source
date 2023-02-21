# What is Mendel Linux?

Mendel Linux is a lightweight derivative of Debian Linux that runs on a number
of Coral development boards, such as the
[Dev Board](https://coral.ai/products/dev-board/) and
[SoM](https://coral.ai/products/som/).

If you're looking to get started with any of the Coral boards, please take a
look at the [Coral doccumentation](https://coral.ai/docs) for more information.

If you want to know what's changed in Mendel, see our
[release notes](https://coral.googlesource.com/docs/+/refs/heads/master/Releases.md).

If you're looking to get started developing, patching, or building Mendel for
your own uses, please read our [Getting Started
documentation](https://coral.googlesource.com/docs/+/refs/heads/master/GettingStarted.md).

Patches, bugreports, and kudos are welcome!

## Why another distribution?

To support Coral's hardware, we needed to build a version of Debian that
produced initial bootable eMMC images and supported our specific peripherals.
Ideally, we'd have liked to use the Debian name, but that wasn't feasable for a
host of reasons.

Suffice it to say, Mendel is considered to be a lightweight "derivative" of the
upstream Debian distribution, and we even use upstream Debian's binary packages
in the project to maintain compatibility and keep up to date with security
fixes.

## How do I get started?

Development in Mendel is unlike writing software for Android or Chrome OS --
those systems are focused on building whole operating system images. Instead,
you write your software like you would for any standard Linux system and package
it up for delivery to the board via the usual apt repository system.

To build an image from our tooling for one of our boards, check out [Getting
Started
documentation](https://coral.googlesource.com/docs/+/refs/heads/master/GettingStarted.md)

Note: we generally discourage this, as we put a great deal of effort into making
sure our releases run well on the boards we target. Mendel is a proper Linux
distribution: we work with packages, not images, and any image should be
possible to upgrade to the latest release with a simple `apt-get dist-upgrade`
without requiring a reboot (modulo kernel and bootloader updates, obviously,
which require [reflashing the board](https://coral.ai/docs/dev-board/reflash/)).

## What do we support?

Mendel currently only supports the Coral Dev Board (also known as
enterprise, or phanbell) and SoM.

For development, our build system only currently supports Linux systems.
Unfortunately, this is due to various factors out of our control, so it is
unlikely that Windows machines will ever be supported. Mac machines may be
supported in the future, but currently is not a high priority for the team.
