pkg_config_cmd = PKG_CONFIG_PATH=$(shell pwd)/../.. pkg-config

all: /tmp/lib64/wkmkclext.so main

wkmkclext-check-init.o: wkmkclext-check-init.c
	gcc -o $@ -c $^ -ggdb -fPIC -DPIC $(shell $(pkg_config_cmd) --cflags  mkcl-1 mkclplug-1 gmodule-2.0)

LISP = mkcl-backtrace.lisp wkmkclext-package.lisp wkmkclext-sendreqcb.lisp wkmkclext.lisp

/tmp/libwkmkclext-library.so: $(LISP)
	mkcl -norc \
		-eval '(load "sample-mkclrc.lisp")' \
		-eval '(load "wkmkclext.system")' \
		-eval "(make:compile-system 'wkmkclext :compile-during-load t :force nil)" \
		-eval '(let ((make::*operations-propagate-to-subsystems* t) (make::*ecl-compile-file-system-p* t)) (make::compile-system :wkmkclext :compile-during-load t :force nil))' \
		-eval '(make::mklib :wkmkclext :ecl-build-type :shared-library :defaults #p"/tmp/" :init-function-name "init_wkmkclext")' \
		-eval '(mkcl:quit)'

/tmp/lib64/wkmkclext.so: /tmp/libwkmkclext-library.so wkmkclext-check-init.o
	mkdir -pv /tmp/lib64
	gcc -o $@ -shared $^ $(shell $(pkg_config_cmd) --libs mkcl-1 mkclplug-1 gmodule-2.0)

test:
	WEBKIT_EXT_DIR=/tmp/lib64 MiniBrowser file:///proc/self/maps

# ./main /tmp/lib64/wkmkclext.so
main: gmodule-test.c
	gcc -o $@ $^ -ggdb $(shell $(pkg_config_cmd) --libs --cflags gmodule-2.0)

clean:
	rm -fv main /tmp/lib64/wkmkclext.so /tmp/libwkmkclext-library.so \
		wkmkclext-check-init.o
