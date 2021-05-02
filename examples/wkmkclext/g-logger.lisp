;;; ;madhu 210439 TEMPORARILY RELOCATED FROM GIRLIB
(defpackage "G-LOGGER"
  #+mkcl
  (:import-from "MKCL" "GETTID")
  (:use "CL" "GIR")
  (:export "G-DEBUG" "G-INFO" "G-WARNING" "G-CRITICAL" "G-MESSAGE"
   "LOG-WITH-TIMINGS"))
(in-package "G-LOGGER")

(eval-when (load eval compile)
  (defconstant +null-pointer+ (cffi:null-pointer)))

(eval-when (load eval compile)
  (defvar *glib* (gir:require-namespace "GLib")))

(eval-when (load eval compile)
(defmacro define-g-loggers ()
  `(progn
     ,@(loop for name in '(g-debug g-message g-info
			   g-warning g-critical g-error)
	     for log-level-name in '(:level-debug :level-message
				     :level-info :level-warning
				     :level-critical :level-error)
	     for log-level = (gir:nget *glib*
				       "LogLevelFlags" log-level-name)
	     collect
	     `(defun ,name (fmt-control &rest fmt-args)
		(gir:invoke (*glib* "log_default_handler")
			    nil ,log-level
			    (apply #'format nil fmt-control fmt-args)
			    +null-pointer+)))
     nil)))

(eval-when (load eval compile)
  (define-g-loggers))

(defun call-g-message-with-timings (fmt-control fmt-args thunk)
  (let ((start (gir:invoke (*glib* "get_monotonic_time"))))
    (g-message "~? ..."  fmt-control fmt-args)
    (funcall thunk)
    (let ((stop (gir:invoke (*glib* "get_monotonic_time"))))
      (g-message "... Done! in ~As."(/ (- stop start) 1e6)))))

;; FIXME
(defmacro log-with-timings ((fmt-control &rest fmt-args) &body body)
  `(let ((thunk (lambda () ,@body)))
     (call-g-message-with-timings ,fmt-control ,fmt-args thunk)))

#+nil
(log-with-timings ("Sleeping  sec") (sleep 2))