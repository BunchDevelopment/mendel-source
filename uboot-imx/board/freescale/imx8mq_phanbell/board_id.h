/*
 * Copyright 2019 Google LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 */

#ifndef __BOARD_ID_H__
#define __BOARD_ID_H__

#include <common.h>

// Returns board id based on gpio pins state:
// 0 - DVT boards with 4Gb Kingston DDR
// 1 - EVT boards with 1Gb Hynix DDR
// 2 - EVT boards with 1Gb Micron DDR
// 3 - DVT boards with 2Gb Kingston DDR
// 4 - DVT boards with 3Gb Micron (MT53B768M32D4NQ-062) DDR
// 5 - DVT boards with 1Gb Hynix DDR
// 6 - DVT boards with 1Gb Micron DDR
// 7 - DVT boards with 3Gb Micron (MT53E768M32D4DT) DDR

int get_board_id(void);
int get_baseboard_id(void);

phys_size_t get_ddr_size(void);
#endif
