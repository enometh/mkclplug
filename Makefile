pkg_config_cmd = PKG_CONFIG_PATH=$(shell pwd) pkg-config

CFLAGS += -ggdb
#CFLAGS += -D_GNU_SOURCE -fno-strict-aliasing -fPIC -O2

PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib64
PKGCONFDIR ?= $(LIBDIR)/pkgconfig

libmkclplug.a: monitorlib.o mkclplug.o
	ar crv $@ $^

mkclplug.o: mkclplug.c
	$(CC) -c -o $@ $^ $(CFLAGS) \
		$(shell $(pkg_config_cmd) --cflags glib-2.0 mkcl-1)

monitorlib.o: monitorlib.c
	$(CC) -c -o $@ $^ $(CFLAGS) $(shell pkg-config --cflags gio-2.0)

install: mkclplug.h libmkclplug.a mkclplug-1.pc install_shared
	cp -apfv mkclplug.h $(DESTDIR)/$(INCLUDEDIR)
	cp -apfv libmkclplug.a $(DESTDIR)/$(LIBDIR)
	cp -apfv mkclplug-1.pc $(DESTDIR)/$(PKGCONFDIR)

uninstall: uninstall_shared
	rm -fv $(DESTDIR)/$(INCLUDEDIR)/mkclplug.h
	rm -fv $(DESTDIR)/$(LIBDIR)/libmkclplug.a
	rm -fv $(DESTDIR)/$(PKGCONFDIR)/mkclplug-1.pc

clean:
	rm -fv main *.o *.a *.lo *.so

main: mkclplugtest.o libmkclplug.a
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
	cp -apfv $^ $(DESTDIR)/$(LIBDIR)