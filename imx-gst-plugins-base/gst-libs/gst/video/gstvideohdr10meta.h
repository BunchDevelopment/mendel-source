/* GStreamer
 * Copyright 2017 NXP
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef __GST_VIDEO_HDR10_META_H__
#define __GST_VIDEO_HDR10_META_H__

#include <gst/gst.h>
#include <gst/video/video.h>

G_BEGIN_DECLS

#define GST_VIDEO_HDR10_META_API_TYPE (gst_video_hdr10_meta_api_get_type())
#define GST_VIDEO_HDR10_META_INFO  (gst_video_hdr10_meta_get_info())

typedef struct _GstHdr10Meta GstHdr10Meta;
typedef struct _GstVideoHdr10Meta GstVideoHdr10Meta;

struct _GstHdr10Meta
{
  guint redPrimary[2];
  guint greenPrimary[2];
  guint bluePrimary[2];
  guint whitePoint[2];
  guint maxMasteringLuminance;
  guint minMasteringLuminance;
  guint maxContentLightLevel;
  guint maxFrameAverageLightLevel;
  guint colourPrimaries;
  guint transferCharacteristics;
  guint matrixCoeffs;
  guint fullRange;
  guint chromaSampleLocTypeTopField;
  guint chromaSampleLocTypeBottomField;
};

struct _GstVideoHdr10Meta
{
  GstMeta meta;

  GstHdr10Meta hdr10meta;
};
GST_EXPORT
GType gst_video_hdr10_meta_api_get_type          (void);

GST_EXPORT
const GstMetaInfo *gst_video_hdr10_meta_get_info (void);

#define gst_buffer_get_video_hdr10_meta(b) \
    ((GstVideoHdr10Meta *)gst_buffer_get_meta((b),GST_VIDEO_HDR10_META_API_TYPE))
GST_EXPORT
GstVideoHdr10Meta *gst_buffer_add_video_hdr10_meta (GstBuffer * buffer);

G_END_DECLS

#endif /* __GST_VIDEO_HDR10_META_H__ */
