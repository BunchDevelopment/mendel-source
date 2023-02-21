# Device tree overlays

The uboot script on Mendel is configured to load device tree blob (`.dtb`) files from `/boot/` and
overlay the existing device tree with any `dtb` files specified in the `/boot/overlays.txt` file.

For example, you can use the following steps to increase the CMA size to 512 MiB
(default is 320 MiB). (All steps are performed on your Mendel device.)

First, create your device tree source (`.dts`) file (in this example, named `cma512.dts`):

```
// Set CMA region to 512M
/dts-v1/;
/plugin/;

/ {
    compatible = "fsl,imx8mq-phanbell";

    fragment@0 {
        target-path = "/";
        __overlay__ {
            reserved-memory {
                linux,cma {
                    size = <0 0x20000000>;
                };
            };
        };
    };
};
```

Install the device tree compiler:

```
sudo apt-get update

sudo apt-get install device-tree-compiler
```

Compile your `dts` file to `dtb` format:

```
dtc -I dts -O dtb -o cma512.dtbo cma512.dts
```

Move the `cma512.dtbo` file into `/boot/` and edit the `/boot/overlays.txt` file (as root) to
include this new file. The `overlays.txt` file should then look like this:

```
# List of device tree overlays to load. Format: overlay=<dtbo name, no extenstion> <dtbo2> ...
overlay=cma512
```

Then reboot and you're done. You can verify the CMA update like this:

```
cat /proc/meminfo | grep CmaTotal
```

It should print `524288 kB`.