#
# Copyright 2016 Freescale Semiconductor
#
# SPDX-License-Identifier:      GPL-2.0+
#

obj-y += imx8mq_phanbell.o board_id.o board_id_cmd.o

ifdef CONFIG_SPL_BUILD
obj-y += spl.o
obj-y += board_id.o
obj-y += ddr/lpddr4_timing_micron_1gb.o
obj-y += ddr/lpddr4_timing_hynix_1gb.o
obj-y += ddr/lpddr4_timing_kingston_2gb.o
obj-y += ddr/lpddr4_timing_kingston_4gb.o
endif
