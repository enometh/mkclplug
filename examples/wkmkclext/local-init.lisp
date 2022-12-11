(in-package "CL-USER")
(when (or #+mkcl(mkcl:getenv "WKEXTSIMPLE")
	  #+ecl(ext:getenv "WKEXTSIMPLE")
	  nil)
  (pushnew :wkmkclext-simple *features*))

(load (merge-pathnames "sample-mkclrc.lisp" *load-truename*))

;; remember `simple' starts off with a blank slate
(load (merge-pathnames "wkmkclext.system"  *load-truename*))
(unless (find-package "WKMKCLEXTEXT")
  (require 'wkmkclext))
