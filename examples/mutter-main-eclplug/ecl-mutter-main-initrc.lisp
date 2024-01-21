;;; -*- Mode: LISP; Package: :cl-user; BASE: 10; Syntax: ANSI-Common-Lisp; -*-
;;;
;;;   Time-stamp: <>
;;;   Touched: Sun Jan 16 11:51:45 2022 +0530 <enometh@net.meer>
;;;   Bugs-To: enometh@net.meer
;;;   Status: Experimental.  Do not redistribute
;;;   Copyright (C) 2022 Madhu.  All Rights Reserved.
;;;
(in-package "CL-USER")
(format t ";;; Now playing ~S~&" *load-pathname*)
;; (pushnew :wk *features*)
#+ecl
(progn
(load "~/.eclrc")
(slynk-start))

#||
(defvar *local-init-loaded* nil)
(unless *local-init-loaded*
  (load "~/cl/mkclplug/examples/mutter-main-eclplug/local-init.lisp")
  (setq *local-init-loaded* t))

(load "~/cl/mkclplug/examples/mutter-main-eclplug/mutter-main-eclplug.system")
(require 'mutter-main-eclplug)
||#