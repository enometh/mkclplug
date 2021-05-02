;; sample-mkclinitrc.lisp which loads up defsystem, and sets up the
;; thirdparty locations for the user.
(defparameter *binary-directory-fasl-root*  #p"~/ecl-fasl/")
(ensure-directories-exist  *binary-directory-fasl-root* :verbose t)
(load "~/cl/extern/defsystem-3.x/lc-lite.lisp")
(lc-lite "~/cl/extern/defsystem-3.x/defsystem.lisp")
(wildset-lpn-translations "EXTERN" "~/cl/extern/")
(wildset-lpn-translations "PROJECTS" "~/cl/")
(setq mk:*central-registry*
      (list (translate-logical-pathname "PROJECTS:registry;")))
(setq mk:*compile-during-load* t)
(setq *compile-verbose* t *load-verbose* t)

