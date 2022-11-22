(in-package "CL-USER")
(load (merge-pathnames "sample-mkclrc.lisp" *load-truename*))
(require 'girlib)

;; remember `simple' starts off with a blank slate
(unless (find-package "WKMKCLEXTEXT")
(progn
  (load (merge-pathnames "wkmkclext.system"  *load-truename*))
  (require 'wkmkclext))
(load (merge-pathnames "wkmkclext-dbus-backdoor.lisp" *load-truename*)))
