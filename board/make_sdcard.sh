#!/bin/bash -x

ROOTFS_DIR=$1
SDCARD_PATH=$2
ROOTDIR=$3

LOOP=$(sudo losetup --show -f $2)
sudo partx -d ${LOOP} || true
sudo partx -a ${LOOP}

sudo mount ${LOOP}p2 $1
sudo mount ${LOOP}p1 $1/boot

sudo cp $3/board/fstab.sdcard $1/etc/fstab

sudo umount $1/boot
sudo umount $1

sudo partx -d ${LOOP}
sudo losetup -d ${LOOP}