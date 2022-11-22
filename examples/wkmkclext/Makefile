# FIXME: can directly set PKG_CONFIG_PATH
pkg_config_cmd = PKG_CONFIG_PATH=$(shell pwd)/../.. pkg-config

CLEANOBJ =

all: /tmp/lib64/wkmkclext.so gmodule-test \
	/tmp/lib64/wkmkclext-simple.so

wkmkclext-check-init.o: wkmkclext-check-init.c
	gcc -o $@ -c $^ -ggdb -fPIC -DPIC $(shell $(pkg_config_cmd) --cflags  mkcl-1 mkclplug-1 gmodule-2.0)

CLEANOBJ += wkmkclext-check-init.o

LISP = mkcl-backtrace.lisp wkmkclext-package.lisp wkmkclext-sendreqcb.lisp wkmkclext.lisp sample-mkclrc.lisp

/tmp/libwkmkclext-library.so: $(LISP)
	mkcl -norc \
		-eval '(setq *features* (delete :wkmkclext-simple *features*))' \
		-eval '(load "sample-mkclrc.lisp")' \
		-eval '(load "wkmkclext.system")' \
		-eval "(make:compile-system 'wkmkclext :compile-during-load t :force nil)" \
		-eval '(let ((make::*operations-propagate-to-subsystems* t) (make::*ecl-compile-file-system-p* t)) (make::compile-system :wkmkclext :compile-during-load t :force nil))' \
		-eval '(make::mklib :wkmkclext :ecl-build-type :shared-library :defaults #p"/tmp/" :init-function-name "init_wkmkclext")' \
		-eval '(mkcl:quit)'

/tmp/lib64/wkmkclext.so: /tmp/libwkmkclext-library.so wkmkclext-check-init.o
	mkdir -pv /tmp/lib64
	gcc -o $@ -shared $^ $(shell $(pkg_config_cmd) --libs mkcl-1 mkclplug-1 gmodule-2.0)

CLEANOBJ += /tmp/lib64/wkmkclext.so /tmp/libwkmkclext-library.so

test:
	WEBKIT_EXT_DIR=/tmp/lib64 MiniBrowser file:///proc/self/maps

# ./gmodule-test /tmp/lib64/wkmkclext.so
gmodule-test: gmodule-test.c
	gcc -o $@ $^ -ggdb $(shell $(pkg_config_cmd) --libs --cflags gmodule-2.0)

CLEANOBJ += gmodule-test

wkmkclext-simple.o: wkext-simple.c
	gcc -c -o $@ $^ -ggdb $(shell $(pkg_config_cmd) --cflags mkcl-1 mkclplug-1 webkit2gtk-web-extension-4.0) -fPIC -DPIC -DWK_MKCL

/tmp/lib64/wkmkclext-simple.so: wkmkclext-simple.o wkmkclext-check-init.o
	mkdir -pv /tmp/lib64
	gcc -o $@ -shared $^ $(shell $(pkg_config_cmd) --libs mkcl-1 mkclplug-1 webkit2gtk-web-extension-4.0)

CLEANOBJ += /tmp/lib64/wkmkclext-simple.so wkmkclext-simple.o

clean:
	rm -fv $(CLEANOBJ)
