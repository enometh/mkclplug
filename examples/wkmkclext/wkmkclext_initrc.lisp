(in-package "COMMON-LISP-USER")
(format t "Now Playing ~S ...~&" *load-pathname*)

(eval-when (load eval compile)
  (require 'cmp))

;; add additional features through a local-init file in the same
;; location if present
(defvar $local-init (merge-pathnames "local-init" *load-pathname*))
(format t "Going after ~S~&" $local-init)
(when (probe-file $local-init) (load $local-init))

#+nil
(progn(load "~/sly-config.lisp")
      (ignore-errors (slynk-start)))
;;(sleep 2)
;;(load (merge-pathnames "wkmkclext-dbus-backdoor.lisp" *load-truename*))