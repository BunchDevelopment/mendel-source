#Copyright 2017 NXP

CC = gcc
CFLAGS ?= -g -O2 -Wall -std=c99 -static
INCLUDE += $(CURR_DIR)/src


vpath $(INCLUDE)

.PHONY:  clean all

.DEFAULT:
	@$(MAKE) --no-print-directory -C $(SOC) -f soc.mak $@

#print out usage as the default target
all: $(MKIMG) help

clean:
	@rm -f $(MKIMG)
	@rm -f src/build_info.h
	@$(MAKE) --no-print-directory -C iMX8M -f soc.mak  clean

buildinfo:
	@echo -n '#define MKIMAGE_COMMIT 0x' > src/build_info.h
	@git rev-parse --short=8 HEAD >> src/build_info.h
	@echo '' >> src/build_info.h

help:
	@echo $(CURR_DIR)
	@echo "usage ${MAKE} SOC=<SOC_TARGET> [TARGET]"
	@echo "i.e.  ${MAKE} SOC=iMX8QX flash_dcd"
	@echo "Common Targets:"
	@echo
	@echo "Parts with SCU"
	@echo "	  flash_scfw    - Only boot SCU"
	@echo "	  flash_dcd     - SCU + AP cluster with DCDs"
	@echo "	  flash         - SCU + AP (no DCD)"
	@echo "	  flash_flexspi - SCU + AP (FlexSPI device) "
	@echo "	  flash_cm4_0   - SCU + M4_0 w/ DCDs "
	@echo "	  flash_all     - SCU + AP + M4 + SCD + CSF(AP & SCU) w/ DCDs"
	@echo ""
	@echo "Parts w/o SCU"
	@echo "	  flash_hdmi_spl_uboot     - HDMI FW + u-boot spl"
	@echo "	  flash_hdmi_spl_uboot_tee - HDMI FW + u-boot spl w/ tee"
	@echo "	  flash_spl_uboot          - u-boot spl"
	@echo "	  flash_spl_uboot_tee      - u-boot spl w/tee"
	@echo
	@echo "Typical flash cmd: dd if=iMX8QM/flash.bin of=/dev/<your device> bs=1k seek=33"
	@echo
