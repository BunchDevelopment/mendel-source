#!/bin/bash -xe

sudo update-binfmts --package qemu-user-static --remove qemu-aarch64 /usr/bin/qemu-aarch64-static
sudo update-binfmts \
	--package qemu-user-static \
	--install qemu-aarch64 /usr/bin/qemu-aarch64-static \
	--magic '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00' \
	--mask '\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff' \
	--offset 0 \
	--credential yes \
	--fix-binary yes
