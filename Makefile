pkg_config_cmd = PKG_CONFIG_PATH=$(shell pwd) pkg-config

CFLAGS += -ggdb
#CFLAGS += -D_GNU_SOURCE -fno-strict-aliasing -fPIC -O2

PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib64
PKGCONFDIR ?= $(LIBDIR)/pkgconfig

#INSTALL ?= cp -apfv
INSTALL ?= rsync -aivzHuOJX --inplace

libmkclplug.a: monitorlib.o mkclplug.o
	ar crv $@ $^

mkclplug.o: mkclplug.c
	$(CC) -c -o $@ $^ $(CFLAGS) \
		$(shell $(pkg_config_cmd) --cflags glib-2.0 mkcl-1)

monitorlib.o: monitorlib.c
	$(CC) -c -o $@ $^ $(CFLAGS) $(shell pkg-config --cflags gio-2.0)

install: mkclplug.h libmkclplug.a mkclplug-1.pc install_shared install_dirs
	$(INSTALL) mkclplug.h $(DESTDIR)/$(INCLUDEDIR)
	$(INSTALL) libmkclplug.a $(DESTDIR)/$(LIBDIR)
	$(INSTALL) mkclplug-1.pc $(DESTDIR)/$(PKGCONFDIR)

install_dirs: $(DESTDIR)/$(INCLUDEDIR) $(DESTDIR)/$(LIBDIR) $(DESTDIR)/$(PKGCONFDIR)
	mkdir -pv $?

uninstall: uninstall_shared
	rm -fv $(DESTDIR)/$(INCLUDEDIR)/mkclplug.h
	rm -fv $(DESTDIR)/$(LIBDIR)/libmkclplug.a
	rm -fv $(DESTDIR)/$(PKGCONFDIR)/mkclplug-1.pc

clean:
	rm -fv main *.o *.a *.lo

mkclplugtest: mkclplugtest.o libmkclplug.a
	$(CC) -o $@ $^ $(LIBS) \
		 $(shell $(pkg_config_cmd) --libs mkclplug-1)

mkclplugtest.o: mkclplugtest.c
	$(CC) -c -o $@ $^ $(CFLAGS) \
		$(shell $(pkg_config_cmd) --cflags mkclplug-1)

libmkclplug.so: monitorlib.lo mkclplug.lo
	$(CC) -shared -o $@ $^

mkclplug.lo: mkclplug.c
	$(CC) -c -o $@ $^ $(CFLAGS) \
		 -fPIC -DPIC \
		$(shell $(pkg_config_cmd) --cflags glib-2.0 mkcl-1)

monitorlib.lo: monitorlib.c
	$(CC) -c -o $@ $^ $(CFLAGS) $(shell pkg-config --cflags gio-2.0) \
		 -fPIC -DPIC

uninstall_shared:
	rm -fv $(DESTDIR)/$(LIBDIR)/libmkclplug.so

install_shared: libmkclplug.so
	$(INSTALL) $^ $(DESTDIR)/$(LIBDIR)
