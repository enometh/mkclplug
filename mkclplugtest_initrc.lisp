(in-package "COMMON-LISP-USER")
(format t "Now Playing ~S ...~&" *load-pathname*)

(progn
  (require 'cmp)
  ;; set up the desired environment
  (load "~/.mkcl")
  (require 'cffi))

#+nil
(progn
  (require 'slynk)
  ;; start slynk at a port (connect to it from emacs)
  (unless (find :slynk *features*)
    (slynk-start)))


#||
;; load and Monitor another file.  (Note you can't call MKCLPLUG's
;; loadlispfile from the slynk thread). also
;; (argv 0) doesn't work for some reason
||#

(defun runtime-initrc-path (&key (pid (mkcl:getpid))
			    (uid (mkcl:getuid))
			     (app-name
			      (cffi:foreign-string-to-lisp
			       (cffi:mem-ref
				(cffi:foreign-symbol-pointer "stashed_appname")
				:pointer))))
  (format nil "/dev/shm/~D-~A-runtime/~D.lisp" uid app-name pid))

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


(cffi:with-foreign-string (initrc (runtime-initrc-path))
  (load-and-monitor initrc (cffi:callback load-lisp-file)
		    nil))

(progn
  (ensure-directories-exist (runtime-initrc-path))
  (unless (probe-file  (runtime-initrc-path))
(with-open-file (stream (runtime-initrc-path) :direction :output
			:if-exists :supersede)
  (write `(in-package "CL-USER") :stream stream)
  (terpri stream)
  (write `(format t "NOW PLAYING ~A~&" *load-pathname*) :stream stream)
  (terpri stream)
  (write `(progn
	    (load "~/sly-config")
	    (require 'slynk)
	    (defvar +pid-start+ 4005)
	    (defvar *slynk-pid* (mkcl::getpid))
	    (defvar *slynk-port* (+ *slynk-pid* +pid-start+))
	    (slynk::create-server :port *slynk-port*)
	    (setf (slynk::debug-on-slynk-error) t)
	    (defun logpid (fmt &rest args)
	      (format t "[~D] ~?~&" *slynk-pid* fmt args))
	    (logpid "Slynk listening on port ~A (~A + ~A)" *slynk-port* *slynk-pid* +pid-start+))
	 :stream stream)
  (terpri stream))))
