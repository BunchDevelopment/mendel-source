include Makefile.sources

libkms_la_LTLIBRARIES = libkms.la
libkms_ladir = $(libdir)
libkms_la_LDFLAGS = -version-number 1:0:0 -no-undefined
libkms_la_LIBADD = $(LIBDRM_LIBS)
libkms_la_CFLAGS = $(LIBDRM_CFLAGS) $(WARN_CFLAGS) -I$(top_srcdir)

libkms_la_SOURCES = $(LIBKMS_FILES)

libkmsincludedir = ${includedir}/libkms
libkmsinclude_HEADERS = $(LIBKMS_H_FILES)

pkgconfigdir = @pkgconfigdir@
pkgconfig_DATA = libkms.pc
