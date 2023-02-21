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


#include "gstvideohdr10meta.h"

#include <string.h>

GType
gst_video_hdr10_meta_api_get_type (void)
{
  static volatile GType type = 0;
  static const gchar *tags[] =
      { GST_META_TAG_VIDEO_STR, GST_META_TAG_VIDEO_ORIENTATION_STR,
    GST_META_TAG_VIDEO_ORIENTATION_STR, NULL
  };

  if (g_once_init_enter (&type)) {
    GType _type =
        gst_meta_api_type_register ("GstVideoHdr10MetaAPI", tags);
    g_once_init_leave (&type, _type);
  }
  return type;
}

static gboolean
gst_video_hdr10_meta_transform (GstBuffer * dest,
    GstMeta * meta, GstBuffer * buffer, GQuark type, gpointer data)
{
  GstVideoHdr10Meta *dmeta, *smeta;

  smeta = (GstVideoHdr10Meta *) meta;

  if (GST_META_TRANSFORM_IS_COPY (type)) {
    dmeta =
        (GstVideoHdr10Meta *) gst_buffer_add_meta (dest,
        GST_VIDEO_HDR10_META_INFO, NULL);

    if (!dmeta)
      return FALSE;

    memcpy (&dmeta->hdr10meta, &smeta->hdr10meta, sizeof (GstHdr10Meta));

  }
  return TRUE;
}

static gboolean
gst_video_hdr10_meta_init (GstMeta * meta, gpointer params,
    GstBuffer * buffer)
{
  return TRUE;
}

const GstMetaInfo *
gst_video_hdr10_meta_get_info (void)
{
  static const GstMetaInfo *info = NULL;

  if (g_once_init_enter ((GstMetaInfo **) & info)) {
    const GstMetaInfo *meta =
        gst_meta_register (GST_VIDEO_HDR10_META_API_TYPE,
        "GstVideoHdr10Meta",
        sizeof (GstVideoHdr10Meta),
        gst_video_hdr10_meta_init,
        NULL,
        gst_video_hdr10_meta_transform);
    g_once_init_leave ((GstMetaInfo **) & info, (GstMetaInfo *) meta);
  }
  return info;
}

GstVideoHdr10Meta *
gst_buffer_add_video_hdr10_meta (GstBuffer * buffer)
{
  GstVideoHdr10Meta *meta;

  g_return_val_if_fail (buffer != NULL, NULL);

  meta =
      (GstVideoHdr10Meta *) gst_buffer_add_meta (buffer,
      GST_VIDEO_HDR10_META_INFO, NULL);

  if (!meta)
    return NULL;

  return meta;
}
