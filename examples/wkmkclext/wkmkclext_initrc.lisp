(in-package "COMMON-LISP-USER")
(format t "Now Playing ~S ...~&" *load-pathname*)

(eval-when (load eval compile)
  (require 'cmp))
