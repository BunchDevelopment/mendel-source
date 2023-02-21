/*
 * Copyright (c) 2010-2012,2014-2015 Freescale Semiconductor, Inc.
 *
 */

/*
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

/*
 * Module Name:    aiuridxtab.c
 *
 * Description:    Implementation of utils for import/export index table
 *                 for unified parser gstreamer plugin
 *
 * Portability:    This code is written for Linux OS and Gstreamer
 */

/*
 * Changelog:
 *
 */

#include <stdio.h>
#include <string.h>

#include "aiurdemux.h"


#define AIUR_IDX_TABLE_MAGIC 0x72756961
#define AIUR_IDX_TABLE_VERSION 0x3

#define AIUR_IDX_TABLE_HEAD_SIZE (sizeof(AiurIdxTabHead)+sizeof(AiurIdxTabInfo)+sizeof(gint))


static unsigned char CRC_table_h[] = {
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
  0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
  0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
  0x00, 0xC1, 0x81, 0x40
};

static unsigned char CRC_talbe_l[] = {
  0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06, 0x07, 0xC7,
  0x05, 0xC5, 0xC4, 0x04, 0xCC, 0x0C, 0x0D, 0xCD, 0x0F, 0xCF, 0xCE, 0x0E,
  0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09, 0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9,
  0x1B, 0xDB, 0xDA, 0x1A, 0x1E, 0xDE, 0xDF, 0x1F, 0xDD, 0x1D, 0x1C, 0xDC,
  0x14, 0xD4, 0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3,
  0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3, 0xF2, 0x32,
  0x36, 0xF6, 0xF7, 0x37, 0xF5, 0x35, 0x34, 0xF4, 0x3C, 0xFC, 0xFD, 0x3D,
  0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A, 0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38,
  0x28, 0xE8, 0xE9, 0x29, 0xEB, 0x2B, 0x2A, 0xEA, 0xEE, 0x2E, 0x2F, 0xEF,
  0x2D, 0xED, 0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26,
  0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60, 0x61, 0xA1,
  0x63, 0xA3, 0xA2, 0x62, 0x66, 0xA6, 0xA7, 0x67, 0xA5, 0x65, 0x64, 0xA4,
  0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F, 0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB,
  0x69, 0xA9, 0xA8, 0x68, 0x78, 0xB8, 0xB9, 0x79, 0xBB, 0x7B, 0x7A, 0xBA,
  0xBE, 0x7E, 0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5,
  0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71, 0x70, 0xB0,
  0x50, 0x90, 0x91, 0x51, 0x93, 0x53, 0x52, 0x92, 0x96, 0x56, 0x57, 0x97,
  0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C, 0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E,
  0x5A, 0x9A, 0x9B, 0x5B, 0x99, 0x59, 0x58, 0x98, 0x88, 0x48, 0x49, 0x89,
  0x4B, 0x8B, 0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
  0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42, 0x43, 0x83,
  0x41, 0x81, 0x80, 0x40
};


static unsigned int
calcCRC16 (unsigned char *buf, int len)
{
  unsigned char high = 0;
  unsigned char low = 0;
  int index = 0;
  int i;
  for (i = 0; i < len; i++) {
    index = low ^ buf[i];
    low = high ^ CRC_table_h[index];
    high = CRC_talbe_l[index];
  }

  index = high;
  index = index << 8;
  index |= low;
  return index;
}

void
aiurdemux_destroy_idx_table (AiurIndexTable * idxtable)
{
  if (idxtable) {
    if (idxtable->coreid) {
      g_free (idxtable->coreid);
    }
    if (idxtable->idx) {
      g_free (idxtable->idx);
    }
  }
}

AiurIndexTable *
aiurdemux_create_idx_table (int size, const char *coreid)
{
  AiurIndexTable *idxtable = g_try_malloc (sizeof (AiurIndexTable));
  if (idxtable) {
    memset (idxtable, 0, sizeof (AiurIndexTable));
    idxtable->head.magic = AIUR_IDX_TABLE_MAGIC;
    idxtable->head.version = AIUR_IDX_TABLE_VERSION;
    if (size) {
      idxtable->idx = g_try_malloc (size);
      if (idxtable->idx == NULL) {
        aiurdemux_destroy_idx_table (idxtable);
        return NULL;
      }
      idxtable->info.size = size;
    }
    if (coreid) {
      int coreid_len = strlen (coreid);
      idxtable->coreid = g_try_malloc (coreid_len);
      if (idxtable->coreid == NULL) {
        aiurdemux_destroy_idx_table (idxtable);
        return NULL;
      }
      memcpy (idxtable->coreid, coreid, coreid_len);
      idxtable->coreid_len = coreid_len;
    }
  }
  return idxtable;
}




AiurIndexTable *
aiurdemux_import_idx_table (gchar * filename)
{
  AiurIndexTable *idxtable = aiurdemux_create_idx_table (0, NULL);
  FILE *fd = fopen (filename, "r");
  unsigned int crc;


  if ((fd == NULL) || (idxtable == NULL))
    goto fail;


  if (fread (idxtable, 1, AIUR_IDX_TABLE_HEAD_SIZE,
          fd) < AIUR_IDX_TABLE_HEAD_SIZE) {
    goto fail;
  }

  if ((idxtable->head.magic != AIUR_IDX_TABLE_MAGIC)
      || (idxtable->head.version != AIUR_IDX_TABLE_VERSION)) {
    goto fail;
  }

  if ((idxtable->info.size > AIUR_IDX_TABLE_MAX_SIZE)) {
    goto fail;
  }

  if (idxtable->coreid_len) {
    gchar *coreid = g_try_malloc (idxtable->coreid_len);
    if (coreid == NULL)
      goto fail;

    if (fread (coreid, 1, idxtable->coreid_len, fd) < 1) {
      g_free (coreid);
      goto fail;
    }

    idxtable->coreid = coreid;
  }

  if (idxtable->info.size) {
    gchar *index = g_try_malloc (idxtable->info.size);
    if (index == NULL)
      goto fail;

    if (fread (index, 1, idxtable->info.size, fd) < 1) {
      g_free (index);
      goto fail;
    }

    if (fread (&idxtable->crc, sizeof (unsigned int), 1, fd) < 1) {
      g_free (index);
      goto fail;
    }

    crc = calcCRC16 (index, idxtable->info.size);

    if (crc != idxtable->crc) {
      g_free (index);
      goto fail;
    }
    idxtable->idx = index;
  }

  if (fd) {
    fclose (fd);
  }

  return idxtable;
fail:
  if (idxtable) {
    aiurdemux_destroy_idx_table (idxtable);
    idxtable = NULL;
  }

  if (fd) {
    fclose (fd);
  }
  return idxtable;
}


int
aiurdemux_export_idx_table (const char *filename, AiurIndexTable * itab)
{
  FILE *fd = NULL;
  unsigned int buf;
  int ret = -1;

  if ((itab == NULL) || (itab->info.size > AIUR_IDX_TABLE_MAX_SIZE)) {
    goto fail;
  }

  fd = fopen (filename, "w");
  if (fd == NULL) {
    goto fail;
  }

  if (fwrite (itab, 1, AIUR_IDX_TABLE_HEAD_SIZE, fd) < AIUR_IDX_TABLE_HEAD_SIZE) {
    goto fail;
  }

  if (itab->coreid_len) {

    if (fwrite (itab->coreid, 1, itab->coreid_len, fd) < itab->coreid_len) {
      goto fail;
    }

  }

  if (itab->info.size) {

    if (fwrite (itab->idx, 1, itab->info.size, fd) < itab->info.size) {
      goto fail;
    }

    buf = calcCRC16 (itab->idx, itab->info.size);

    if (fwrite (&buf, sizeof (unsigned int), 1, fd) < 1) {
      goto fail;
    }
  }
  ret = 0;
fail:

  if (fd) {
    fclose (fd);
  }
  return ret;
}
