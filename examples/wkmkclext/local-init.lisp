(in-package "CL-USER")
(when (or #+mkcl(mkcl:getenv "WKEXTSIMPLE")
	  #+ecl(ext:getenv "WKEXTSIMPLE")
	  nil)
  (pushnew :wkmkclext-simple *features*))
(load (merge-pathnames "sample-mkclrc.lisp" *load-truename*))
(require 'girlib)

;; remember `simple' starts off with a blank slate
(unless (find-package "WKMKCLEXTEXT")
(progn
  (load (merge-pathnames "wkmkclext.system"  *load-truename*))
  (require 'wkmkclext))
(load (merge-pathnames "wkmkclext-dbus-backdoor.lisp" *load-truename*)))
