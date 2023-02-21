# Mendel release notes

This is a non-exhaustive summary of changes included in each version of Mendel.

To check your Mendel version, run `cat /etc/mendel_version`.

For system image downloads, see [coral.ai/software](https://coral.ai/software/).

## 5.3 (eagle)

+   Updated preinstalled packages (python3-pycoral, libedgetpu1-std,
    python3-edgetpuvision) to grouper ML release
+   Fixed boot from SD cards
+   Fixed MDT compatibility with Python 3.9
+   Added backup apt sources

New Mendel 5.3 image is released for the Coral Dev Board and SoM (file
version `20211117215217`).

## 5.2 (eagle)

+   Updated Python packages to support
    [PyCoral](https://coral.ai/docs/reference/py/)
+   Further support in uboot for 2 GB boards
+   Various kernel updates, including:
    +   defconfig: Include USB FTDI driver
    +   defconfig: Add micro k8s / k3s deps
    +   apex: Add power control
    +   m4: Add M4 device tree overlay
    +   i2s: Enable I2S output on 40-pin header
    +   rt5645: Add a sysfs-based override for hp-detect

**Updated June 2021:** We released a new Mendel 5.2 image for the Coral
Dev Board and SoM (file version `20210518200035`) that includes a critical
patch for the NXP SoC. (Does not apply to the Dev Board Mini.)


## 5.0 (eagle)

+   Upgraded U-Boot bootloader to v2019.04
+   Upgraded Vivante GPU drivers
+   Added support for new 2 GB and 4 GB SoM configurations
+   Separated /home with a partition layout change, so the Home directory is
     now preserved across system flashes
+   Moved all Mendel packages to a more stable APT repository


## 4.0 (day)

+   First release based on [Debian 10 (buster)](
    https://www.debian.org/releases/buster/arm64/release-notes/ch-whats-new.en.html)
    (Note that our distribution does not include everything from Debian;
     for example, Mendel does not include desktop environments and applications,
     because our system is designed for embedded systems. Also, the
     new SecureBoot and AppArmor changes do not apply to Mendel)
+   Support for Python 3.7
+   Support for OpenCV and OpenCL
+   Support for device tree overlays
+   Upgraded GStreamer pipelines
+   Upgraded Linux Kernel (4.14)
+   Upgraded U-Boot bootloader (2017.03.3)


## 3.0 (chef)

+   First open source release
+   First release with the Mendel Development Tool (MDT)
+   Improved security for SSH authentication


## 2.0 (beaker)

+   Resolved Hynix/Micron memory timing stability
+   Support for USB-C connections in U-Boot
+   Support for Mac in flash.sh script
+   Released edgetpu_demo for out-of-box Edge TPU demo


## 1.0 (alpha)

Our first Mendel release!
