(in-package "COMMON-LISP-USER")
(format t "Now Playing ~S ...~&" *load-pathname*)

#+nil
(progn
  (require 'cmp)
  ;; set up the desired environment
  (load "~/.mkcl")
  (require 'cffi)

  (require 'slynk)
  ;; start slynk at a port (connect to it from emacs)
  (unless (find :slynk *features*)
    (slynk-start)))

#||
;; e.g. load and Monitor another file.  (Note you can't call MKCLPLUG's
;; loadlispfile from the slynk thread)

(cffi:defcallback load-lisp-file :void ((path :string))
  (format t "load-lisp-file ~A~&" path)
  (prog nil
     (handler-bind ((error (lambda (error)
			      (write-lisp-backtrace error)
			      (return))))
       (load path))))

(cffi:defcfun (load-and-monitor "load_and_monitor") :void
    (lispfilepath :pointer)
    (watchedcb :pointer)
    (unwatchp :boolean))

(cffi:with-foreign-string (initrc "/dev/shm/local-initrc.lisp")
  (load-and-monitor initrc (cffi:callback load-lisp-file)
		    nil))
||#