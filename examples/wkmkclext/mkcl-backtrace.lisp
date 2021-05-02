(defpackage "MKCL-BACKTRACE"
  (:use "CL")
  (:export
   "WRITE-STACK-BACKTRACE"
   "CALL-WITH-DEBUGGING-ENVIRONMENT"
   "IGNORING-ERRORS"))
(in-package "MKCL-BACKTRACE")

(defun d (arg)
  (mapcar (lambda (slot-name)
            (cons slot-name
                  (if (slot-boundp arg slot-name)
                      (slot-value arg slot-name)
                      'unbound)))
          (mapcar
           #'c2mop:slot-definition-name
           (c2mop:class-slots (class-of arg)))))

(defmethod print-object :around (obj stream)
  (if (member (class-of obj) (mapcar 'find-class nil #+nil '(si::undefined-function)))
      (print-unreadable-object (obj stream :type t :identity t)
        (write (d obj) :stream stream))
      (call-next-method)))

(defun write-stack-backtrace (error stream)
  (declare (special *backtrace*))
  (write-char #\Page stream)
  (format stream "--------------------- BACKTRACE ----------------~&")
  (if (and (typep error 'simple-condition)
	   (simple-condition-format-control error))
      (apply 'format stream "~S: ~@?" error
	     (simple-condition-format-control error)
	     (simple-condition-format-arguments error))
      (format stream "~S" error))
  (terpri stream)
  (loop for i below (length *backtrace*) do
	(format stream "~D: " i)
	(format stream "~A" (first (elt *backtrace* i)))
	(terpri stream))
  (format stream "---------------------- END -----------------------~&"))


(defun call-with-debugging-environment (debugger-loop-fn)
  (let* ((si::*ihs-top* (si::ihs-top))
	 (si::*ihs-current* si::*ihs-top*)
	 (si::*frs-base* (or (si::sch-frs-base si::*frs-top* si::*ihs-base*)
			     (1+ (si::frs-top))))
	 (si::*frs-top* (si::frs-top))
	 (si::*tpl-level* (1+ si::*tpl-level*))
	 (*backtrace* (loop for ihs from 0 below si::*ihs-top*
			    collect (list (si::ihs-fun ihs)
					  (si::ihs-env ihs)
					  nil))))
    (declare (special *backtrace*))
    (loop for f from si::*frs-base* until si::*frs-top*
	  do (let ((i (- (si::frs-ihs f) si::*ihs-base* 1)))
	       (when (plusp i)
		 (let* ((x (elt *backtrace* i))
			(name (si::frs-tag f)))
		   (unless (si::fixnump name)
		     (push name (third x)))))))
    (setf *backtrace* (nreverse *backtrace*))
    (si::set-break-env)
    (si::set-current-ihs)
    (let ((si::*ihs-base* si::*ihs-top*))
      (funcall debugger-loop-fn))))

(defmacro ignoring-errors (&body forms)
  `(prog nil
      (handler-bind ((error (lambda (error)
			      (write-stack-backtrace error *error-output*)
			      (return))))
	(return (call-with-debugging-environment
		 (lambda () ,@forms))))))


