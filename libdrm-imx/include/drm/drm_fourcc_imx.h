/*
 * Copyright 2011 Intel Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * VA LINUX SYSTEMS AND/OR ITS SUPPLIERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef DRM_FOURCC_IMX_H
#define DRM_FOURCC_IMX_H

#include "drm.h"
#include "drm_fourcc.h"

#if defined(__cplusplus)
extern "C" {
#endif

#define DRM_FORMAT_P010		fourcc_code('P', '0', '1', '0') /* 2x2 subsampled Cr:Cb plane, 10-bit per channel */

#define DRM_FORMAT_MOD_VENDOR_AMPHION  0x08
#define DRM_FORMAT_MOD_VENDOR_VSI      0x09

/* Vivante framebuffer modifiers */

/*
 * Vivante 4x4 tiling layout
 *
 * This is a simple tiled layout using tiles of 4x4 pixels in a row-major
 * layout.
 */
#define DRM_FORMAT_MOD_VIVANTE_TILED		fourcc_mod_code(VIVANTE, 1)

/*
 * Vivante 64x64 super-tiling layout
 *
 * This is a tiled layout using 64x64 pixel super-tiles, where each super-tile
 * contains 8x4 groups of 2x4 tiles of 4x4 pixels (like above) each, all in row-
 * major layout.
 *
 * For more information: see
 * https://github.com/etnaviv/etna_viv/blob/master/doc/hardware.md#texture-tiling
 */
#define DRM_FORMAT_MOD_VIVANTE_SUPER_TILED	fourcc_mod_code(VIVANTE, 2)

/*
 * Vivante 4x4 tiling layout for dual-pipe
 *
 * Same as the 4x4 tiling layout, except every second 4x4 pixel tile starts at a
 * different base address. Offsets from the base addresses are therefore halved
 * compared to the non-split tiled layout.
 */
#define DRM_FORMAT_MOD_VIVANTE_SPLIT_TILED	fourcc_mod_code(VIVANTE, 3)

/*
 * Vivante 64x64 super-tiling layout for dual-pipe
 *
 * Same as the 64x64 super-tiling layout, except every second 4x4 pixel tile
 * starts at a different base address. Offsets from the base addresses are
 * therefore halved compared to the non-split super-tiled layout.
 */
#define DRM_FORMAT_MOD_VIVANTE_SPLIT_SUPER_TILED fourcc_mod_code(VIVANTE, 4)

/*
 * Vivante 64x64 super-tiling with compression layout
 *
 * This is a tiled layout using 64x64 pixel super-tiles, where each super-tile
 * contains 8x4 groups of 2x4 tiles of 4x4 pixels each, all in row-major layout
 * with compression.
 */
#define DRM_FORMAT_MOD_VIVANTE_SUPER_TILED_FC  fourcc_mod_code(VIVANTE, 5)


/* Amphion tiled layout */

/*
 * Amphion 8x128 tiling layout
 *
 * This is a tiled layout using 8x128 pixel vertical strips, where each strip
 * contains 1x16 groups of 8x8 pixels in a row-major layout.
 */
#define DRM_FORMAT_MOD_AMPHION_TILED fourcc_mod_code(AMPHION, 1)

/* Verisilicon framebuffer modifiers */

/*
 * Verisilicon 8x4 tiling layout
 *
 * This is G1 VPU tiled layout using tiles of 8x4 pixels in a row-major
 * layout.
 */
#define DRM_FORMAT_MOD_VSI_G1_TILED fourcc_mod_code(VSI, 1)

/*
 * Verisilicon 4x4 tiling layout
 *
 * This is G2 VPU tiled layout using tiles of 4x4 pixels in a row-major
 * layout.
 */
#define DRM_FORMAT_MOD_VSI_G2_TILED fourcc_mod_code(VSI, 2)

/*
 * Verisilicon 4x4 tiling with compression layout
 *
 * This is G2 VPU tiled layout using tiles of 4x4 pixels in a row-major
 * layout with compression.
 */
#define DRM_FORMAT_MOD_VSI_G2_TILED_COMPRESSED fourcc_mod_code(VSI, 3)

#if defined(__cplusplus)
}
#endif

#endif /* DRM_FOURCC_H */
