;;; -*- Mode: LISP; Package: :cl-user; BASE: 10; Syntax: ANSI-Common-Lisp; -*-
;;;
;;;   Time-stamp: <>
;;;   Touched: Sun Jan 09 08:02:33 2022 +0530 <enometh@net.meer>
;;;   Bugs-To: enometh@net.meer
;;;   Status: Experimental.  Do not redistribute
;;;   Copyright (C) 2022 Madhu.  All Rights Reserved.
;;;
;;; WIP - generate module forms

(defpackage "MKCLPLUG-GENMOD"
  (:use "CL"))
(in-package "MKCLPLUG-GENMOD")

(defun make-compile-form (module-name &key
			  (init-function-name
			   (format nil "init_~(~a~)" module-name))
			  (output-directory #p"/tmp/"))
  `(progn
     ;; compile fas files
     (mk:oos ,module-name :compile :compile-during-load t)
     ;; compile shared objects
     (let ((make::*operations-propagate-to-subsystems* t)
	   (make::*ecl-compile-file-system-p* t))
       (make::compile-system ,module-name
			     :compile-during-load t :force nil))
     ;; dump /tmp/lib<module-name>-library.so
     (mk::mklib ,module-name :ecl-build-type :shared-library
		:defaults ,output-directory
		:init-function-name ,init-function-name)
     (mkcl:quit)))

#+nil
(make-compile-form :foo)

(defun make-gmodule-check-init-string (init-function-name app-name)
  (format nil "
#include <gmodule.h>
#include <mkcl/mkcl.h>
#include <mkclplug.h>

extern void ~a (MKCL, mkcl_object, mkcl_object);

const char *
g_module_check_init (GModule * module)
{
  g_message (\"g_module_check_init(%s):\", g_module_name (module));
  void *loc;
  if (!g_module_symbol (module, \"~:*~a\", &loc))
    {
      return \"failed to provide ~:*~a\";
    }
  mkcl_initialize_module (~s, ~:*~:*~a);
  return NULL;
}
"
	  init-function-name app-name))

#+nil
(pprint (make-gmodule-check-init-string "init_foo" "foo"))

#+nil
(defun string->file (string path)
  (with-open-file (stream path :direction :output :if-exists :supersede)
    (write-string string stream)))

#+nil
(string->file (with-output-to-string (*standard-output*)
		(pprint  (make-compile-form :foo)))
	      "/dev/shm/compile-foo.lisp")
#+nil
(string->file (make-gmodule-check-init-string "init_foo" "FOO")
	      "/dev/shm/foo-gmodule-check-init.c")


(defun make-config-override-string (module-name)
  (format nil "
(defparameter *~(~a~)-source-dir* \"/dev/shm/~:*~(~a~)/\")
(defparameter *~:*~(~a~)-binary-dir* (binary-directory ~:*~(~a~)*-source-dir*))
(load (merge-pathnames \"~:*~(~a~):.system\"  ~:*~(~a~)-source-dir*))
"
	module-name
))

#+nil
(string->file (make-config-override-string :foo) "/dev/shm/foo-config.lisp")

#+nil
(string->file (make-config-override-string :wkmkclext) "/dev/shm/wkclmkext-config.lisp")

(defun dump-make-script (module-name)
  (format t "mkcl -load ../wkmkclext/sample-mkclrc.lisp -load ~(~a~)-config.lisp -load /dev/shm/compile-~:*~(~a~).lisp~&" module-name)

  (format t "(export PKG_CONFIG_PATH=../.. ; gcc -c -fPIC -DPIC /dev/shm/~(~a~)-gmodule-check-init.c $(pkg-config --cflags mkcl-1 gmodule-2.0 mkclplug-1))~&" module-name)

  (format t "(export PKG_CONFIG_PATH=../.. ; gcc -o /tmp/lib64/~(~a~).so -shared ~:*~(~a~)-gmodule-check-init.o /tmp/lib~:*~(~a~)-library.so  $(pkg-config --libs mkcl-1 gmodule-2.0 mkclplug-1))~&" module-name))

#+nil
(string->file (with-output-to-string (*standard-output*)
		(dump-make-script :foo))
	      "/dev/shm/1.sh")

#+nil
(string->file (with-output-to-string (*standard-output*)
		(dump-make-script :wkmkclext))
	      "/dev/shm/1.sh")


#||
mkcl -load ../wkmkclext/sample-mkclrc.lisp -load foo-config.lisp -load /dev/shm/compile-foo.lisp &
(export PKG_CONFIG_PATH=../.. ; gcc -c -fPIC -DPIC /dev/shm/foo-gmodule-check-init.c $(pkg-config --cflags mkcl-1 gmodule-2.0 mkclplug-1))
(export PKG_CONFIG_PATH=../.. ; gcc -o /tmp/lib64/foo.so -shared foo-gmodule-check-init.o /tmp/libfoo-library.so  $(pkg-config --libs mkcl-1 gmodule-2.0 mkclplug-1))
ldd /tmp/libfoo-library.so
ldd /tmp/lib64/foo.so
LD_DEBUG=all
../wkmkclext/gmodule-test /tmp/lib64/foo.so &
||#
