#Copyright 2018 NXP
SHELL := /bin/bash

OUTIMG = flash.bin
DCD_CFG_SRC = imx8mq_dcd.cfg
DCD_CFG = imx8mq_dcd.cfg.tmp

CC ?= gcc
CFLAGS ?= -O2 -Wall -std=c99 -static
INCLUDE = ./lib

WGET = /usr/bin/wget
N ?= latest
SERVER=http://yb2.am.freescale.net
DIR = build-output/Linux_IMX_4.9_morty_trunk_next_mx8/$(N)/common_bsp
FW_DIR = imx-boot/imx-boot-tools/imx8mq

rootdir = ../../..
ifeq ($(TARGET_PRODUCT), iot_imx8m_phanbell)
device_name = phanbell
vendor_binary = $(rootdir)/imx-firmware/imx8m
uboot_out = $(rootdir)/out/target/product/imx8m_$(device_name)/obj/UBOOT_OBJ
else ifeq ($(TARGET_PRODUCT), iot_imx8m_ref)
vendor_binary = $(rootdir)/vendor/bsp/freescale/imx8m/phanbell/u-boot
uboot_out = $(rootdir)/out/target/product/imx8m_ref/obj/UBOOT_OBJ
else
$(error Not supported target $(TARGET_PRODUCT))
endif
PATH := $(realpath $(rootdir)/prebuilts/misc/linux-x86/dtc):$(PATH)

BL31 = $(vendor_binary)/bl31.bin
BL33 = $(uboot_out)/u-boot-nodtb.bin
u_boot_spl = $(uboot_out)/spl/u-boot-spl.bin
mkimage_uboot = $(uboot_out)/tools/mkimage_uboot
fsl_dtb = $(uboot_out)/arch/arm/dts/fsl-imx8mq-$(device_name).dtb
signed_hdmi_imx8m = $(vendor_binary)/signed_hdmi_imx8m.bin
lpddr4_pmu_train_1d_dmem = $(vendor_binary)/lpddr4_pmu_train_1d_dmem.bin
lpddr4_pmu_train_1d_imem = $(vendor_binary)/lpddr4_pmu_train_1d_imem.bin
lpddr4_pmu_train_2d_dmem = $(vendor_binary)/lpddr4_pmu_train_2d_dmem.bin
lpddr4_pmu_train_2d_imem = $(vendor_binary)/lpddr4_pmu_train_2d_imem.bin
mkimage_imx8 = $(vendor_binary)/mkimage_imx8

$(DCD_CFG): $(DCD_CFG_SRC)
	@echo "Converting iMX8M DCD file"
	$(CC) -E -Wp,-MD,.imx8mq_dcd.cfg.cfgtmp.d  -nostdinc -Iinclude -I$(INCLUDE) -x c -o $(DCD_CFG) $(DCD_CFG_SRC)

u-boot-spl-ddr.bin: $(u_boot_spl) $(lpddr4_pmu_train_1d_imem) $(lpddr4_pmu_train_1d_dmem) $(lpddr4_pmu_train_2d_imem) $(lpddr4_pmu_train_2d_dmem)
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 $(lpddr4_pmu_train_1d_imem) lpddr4_pmu_train_1d_imem_pad.bin
	@objcopy -I binary -O binary --pad-to 0x4000 --gap-fill=0x0 $(lpddr4_pmu_train_1d_dmem) lpddr4_pmu_train_1d_dmem_pad.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 $(lpddr4_pmu_train_2d_imem) lpddr4_pmu_train_2d_imem_pad.bin
	@cat lpddr4_pmu_train_1d_imem_pad.bin lpddr4_pmu_train_1d_dmem_pad.bin > lpddr4_pmu_train_1d_fw.bin
	@cat lpddr4_pmu_train_2d_imem_pad.bin $(lpddr4_pmu_train_2d_dmem) > lpddr4_pmu_train_2d_fw.bin
	@cat $(u_boot_spl) lpddr4_pmu_train_1d_fw.bin lpddr4_pmu_train_2d_fw.bin > u-boot-spl-ddr.bin
	@rm -f lpddr4_pmu_train_1d_fw.bin lpddr4_pmu_train_2d_fw.bin lpddr4_pmu_train_1d_imem_pad.bin lpddr4_pmu_train_1d_dmem_pad.bin lpddr4_pmu_train_2d_imem_pad.bin

u-boot-spl-ddr4.bin: $(u_boot_spl) ddr4_imem_1d.bin ddr4_dmem_1d.bin ddr4_imem_2d.bin ddr4_dmem_2d.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 ddr4_imem_1d.bin ddr4_imem_1d_pad.bin
	@objcopy -I binary -O binary --pad-to 0x4000 --gap-fill=0x0 ddr4_dmem_1d.bin ddr4_dmem_1d_pad.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 ddr4_imem_2d.bin ddr4_imem_2d_pad.bin
	@cat ddr4_imem_1d_pad.bin ddr4_dmem_1d_pad.bin > ddr4_1d_fw.bin
	@cat ddr4_imem_2d_pad.bin ddr4_dmem_2d.bin > ddr4_2d_fw.bin
	@cat $(u_boot_spl) ddr4_1d_fw.bin ddr4_2d_fw.bin > u-boot-spl-ddr4.bin
	@rm -f ddr4_1d_fw.bin ddr4_2d_fw.bin ddr4_imem_1d_pad.bin ddr4_dmem_1d_pad.bin ddr4_imem_2d_pad.bin

u-boot-spl-ddr3l.bin: $(u_boot_spl) ddr3_imem_1d.bin ddr3_dmem_1d.bin
	@objcopy -I binary -O binary --pad-to 0x8000 --gap-fill=0x0 ddr3_imem_1d.bin ddr3_imem_1d.bin_pad.bin
	@cat ddr3_imem_1d.bin_pad.bin ddr3_dmem_1d.bin > ddr3_pmu_train_fw.bin
	@cat $(u_boot_spl) ddr3_pmu_train_fw.bin > u-boot-spl-ddr3l.bin
	@rm -f ddr3_pmu_train_fw.bin ddr3_imem_1d.bin_pad.bin

u-boot-atf.bin: u-boot.bin $(BL31)
	@cp $(BL31) u-boot-atf.bin
	@dd if=u-boot.bin of=u-boot-atf.bin bs=1K seek=128

u-boot-atf-tee.bin: u-boot.bin $(BL31) tee.bin
	@cp $(BL31) u-boot-atf-tee.bin
	@dd if=tee.bin of=u-boot-atf-tee.bin bs=1K seek=128
	@dd if=u-boot.bin of=u-boot-atf-tee.bin bs=1M seek=1

.PHONY: clean
clean:
	@rm -f $(DCD_CFG) .imx8mq_dcd.cfg.cfgtmp.d u-boot-atf.bin u-boot-atf-tee.bin u-boot-spl-ddr.bin u-boot.itb u-boot.its u-boot-ddr3l.itb u-boot-ddr3l.its u-boot-spl-ddr3l.bin u-boot-ddr4.itb u-boot-ddr4.its u-boot-spl-ddr4.bin $(OUTIMG)

dtbs = $(fsl_dtb)
u-boot.itb: $(dtbs)
	source mkimage_fit_atf.sh $(BL31) $(BL33) $(dtbs) > u-boot.its
	./$(mkimage_uboot) -E -p 0x3000 -f u-boot.its u-boot.itb
	@rm -f u-boot.its

dtbs_ddr3l = fsl-imx8mq-ddr3l-arm2.dtb
u-boot-ddr3l.itb: $(dtbs_ddr3l)
	source mkimage_fit_atf.sh $(BL31) $(BL33) $(dtbs_ddr3l) > u-boot-ddr3l.its
	./$(mkimage_uboot) -E -p 0x3000 -f u-boot-ddr3l.its u-boot-ddr3l.itb

dtbs_ddr4 = fsl-imx8mq-ddr4-arm2.dtb
u-boot-ddr4.itb: $(dtbs_ddr4)
	source mkimage_fit_atf.sh $(BL31) $(BL33) $(dtbs_ddr4) > u-boot-ddr4.its
	./$(mkimage_uboot) -E -p 0x3000 -f u-boot-ddr4.its u-boot-ddr4.itb

flash_evk:  $(signed_hdmi_imx8m) u-boot-spl-ddr.bin u-boot.itb
	./$(mkimage_imx8) -fit -signed_hdmi $(signed_hdmi_imx8m) -loader u-boot-spl-ddr.bin 0x7E1000 -second_loader u-boot.itb 0x40200000 0x60000 -out $(OUTIMG)

flash_ddr3l_arm2:  $(signed_hdmi_imx8m) u-boot-spl-ddr3l.bin u-boot-ddr3l.itb
	./$(mkimage_imx8) -fit -signed_hdmi $(signed_hdmi_imx8m) -loader u-boot-spl-ddr3l.bin 0x7E1000 -second_loader u-boot-ddr3l.itb 0x40200000 0x60000 -out $(OUTIMG)

flash_ddr4_arm2:  $(signed_hdmi_imx8m) u-boot-spl-ddr4.bin u-boot-ddr4.itb
	./$(mkimage_imx8) -fit -signed_hdmi $(signed_hdmi_imx8m) -loader u-boot-spl-ddr4.bin 0x7E1000 -second_loader u-boot-ddr4.itb 0x40200000 0x60000 -out $(OUTIMG)

flash_evk_no_hdmi:  u-boot-spl-ddr.bin u-boot.itb
	./$(mkimage_imx8) -fit -loader u-boot-spl-ddr.bin 0x7E1000 -second_loader u-boot.itb 0x40200000 0x60000 -out $(OUTIMG)

flash_ddr3l_arm2_no_hdmi:  u-boot-spl-ddr3l.bin u-boot-ddr3l.itb
	./$(mkimage_imx8) -fit -loader u-boot-spl-ddr3l.bin 0x7E1000 -second_loader u-boot-ddr3l.itb 0x40200000 0x60000 -out $(OUTIMG)

flash_ddr4_arm2_no_hdmi:  u-boot-spl-ddr4.bin u-boot-ddr4.itb
	./$(mkimage_imx8) -fit -loader u-boot-spl-ddr4.bin 0x7E1000 -second_loader u-boot-ddr4.itb 0x40200000 0x60000 -out $(OUTIMG)

flash_hdmi_spl_uboot: flash_evk

flash_spl_uboot: flash_evk_no_hdmi

print_fit_hab: $(BL33) $(BL31) $(dtbs)
	source print_fit_hab.sh 0x60000 $(dtbs)

nightly :
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_1d_dmem.bin -O lpddr4_pmu_train_1d_dmem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_1d_imem.bin -O lpddr4_pmu_train_1d_imem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_2d_dmem.bin -O lpddr4_pmu_train_2d_dmem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/lpddr4_pmu_train_2d_imem.bin -O lpddr4_pmu_train_2d_imem.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/bl31-imx8mq.bin -O bl31.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/u-boot-spl.bin-imx8mqevk-sd -O u-boot-spl.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/u-boot-nodtb.bin -O u-boot-nodtb.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/fsl-imx8mq-evk.dtb -O fsl-imx8mq-evk.dtb
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/signed_hdmi_imx8m.bin -O signed_hdmi_imx8m.bin
	@$(WGET) -q $(SERVER)/$(DIR)/$(FW_DIR)/mkimage_uboot -O mkimage_uboot

#flash_dcd_uboot:  $(DCD_CFG) u-boot-atf.bin
#	./mkimage_imx8 -dcd $(DCD_CFG) -loader u-boot-atf.bin 0x40001000 -out $(OUTIMG)

#flash_plugin:  plugin.bin u-boot-spl-for-plugin.bin
#	./mkimage_imx8 -plugin plugin.bin 0x912800 -loader u-boot-spl-for-plugin.bin 0x7F0000 -out $(OUTIMG)
