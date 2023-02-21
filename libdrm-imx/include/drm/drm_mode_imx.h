/*
 * Copyright (c) 2007 Dave Airlie <airlied@linux.ie>
 * Copyright (c) 2007 Jakob Bornecrantz <wallbraker@gmail.com>
 * Copyright (c) 2008 Red Hat Inc.
 * Copyright (c) 2007-2008 Tungsten Graphics, Inc., Cedar Park, TX., USA
 * Copyright (c) 2007-2008 Intel Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#ifndef _DRM_MODE_IMX_H
#define _DRM_MODE_IMX_H

#include "drm.h"
#include "drm_mode.h"

#if defined(__cplusplus)
extern "C" {
#endif

enum supported_eotf_type {
	TRADITIONAL_GAMMA_SDR = 0,
	TRADITIONA_GAMMA_HDR,
	SMPTE_ST2084,
	FUTURE_EOTF
};

/* HDR Metadata */
struct hdr_static_metadata {
	__u8 eotf;
	__u8 type;
	__u16 display_primaries_x[3];
	__u16 display_primaries_y[3];
	__u16 white_point_x;
	__u16 white_point_y;
	__u16 max_mastering_display_luminance;
	__u16 min_mastering_display_luminance;
	__u16 max_fall;
	__u16 max_cll;
};

#if defined(__cplusplus)
}
#endif

#endif
