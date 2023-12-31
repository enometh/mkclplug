;;; -*- Mode: LISP; Package: :cl-user; BASE: 10; Syntax: ANSI-Common-Lisp; -*-
;;;
;;;   Time-stamp: <>
;;;   Touched: Sat Dec 10 15:50:46 2022 +0530 <enometh@net.meer>
;;;   Bugs-To: enometh@net.meer
;;;   Status: Experimental.  Do not redistribute
;;;   Copyright (C) 2022 Madhu.  All Rights Reserved.
;;;
(defpackage "WKMKCLEXTLIB"
  (:use "CL" "GIR-LIB" "GIR")
  (:export
   "WEB-VIEW"
   "WEB-CONTEXT"
   "WEB-EXTENSION"
   "WEB-PAGE"
   "DEFINE-USER-MESSAGE-HANDLER-FOR"
   "EVAL-JAVASCRIPT-SYNC"
   "EVAL-JAVASCRIPT"
   "$JS-RESULT"))
(in-package "WKMKCLEXTLIB")

(defvar $user-message-receivers
  (list (nget *wk* "WebContext")
	(nget *wk* "WebView")
	(nget *wkext* "WebExtension")
	(nget *wkext* "WebPage")))

#+nil
(gir::info-get-name(gir::info-of (nget *wk* "WebContext")))

(defun camel (string)
  (cl-user::map-concatenate 'string
			    'string-capitalize
			    (cl-user::string-split-map #(#\-)
						       (string string))
			    ""))

#+nil
(equal (camel "foo-bar") "FooBar")

(defun find-user-message-receiver-class (symbol)
  (let ((target-name (camel symbol)))
    (find-if (lambda (x)
	       (equal target-name (gir:info-get-name (gir:info-of x))))
	     $user-message-receivers)))

#+nil
(find-user-message-receiver-class 'web-context)

#+nil
(gir::get-signal-desc (nget *wk* "WebView") "user-message-received")

(defmacro define-user-message-handler-for (receiver &key (package *package*))
  (assert (find receiver '(web-view web-context web-extension web-page)))
  (let* ((fn (intern
	      (format nil "USER-MESSAGE-RECEIVED-BY-~@:(~A~)" receiver)
	      package))
	 (vn (intern (format nil "$~A-HOOK" fn) package))
	 (sn (intern (format nil "$~A-SID" fn) package))
	 (cn (intern (format nil "CONNECT-~A" fn) package)))
    `(progn
       (defvar ,vn nil
	 "If Non-NIL must be a function which takes four args - the object receiving the signal, a keyword denoting the message name, unmarshalled lisp arguments and the original WebKitMessage object. The function must return T to handle the message.")
       (defvar ,sn nil)
       (defun ,cn (obj)
	 (if ,sn (gir:disconnect obj ,sn))
	 (setq ,sn (gir:connect obj "user-message-received" ',fn)))
       (defun ,fn (self message)
	 (let (name key args)
	   (g-message "user message received by ~a (~S): name: ~S params: ~S"
		      ',receiver self
		      (setq name (property message "name"))
		      (setq args (convert-from-gvariant (property message "parameters"))))
	   (handler-case (when ,vn
			   (let ((ret (funcall self ,vn
					       (intern (string-upcase name "KEYWORD"))
					       args)))
			     (and ret t)))
	     (error (c)
	       (gir::warning ,(format nil "error executing ~a" vn))
	       (cl-user::write-lisp-backtrace c)
	       nil)))))))

#+nil
(define-user-message-handler-for web-view)


;;; ----------------------------------------------------------------------
;;;
;;;
;;;

#||
(get-method-desc (nget *wk* "WebView") "run_javascript")
;; => #F<run_javascript(#V<script: STRING> #V<cancellable: #O<Cancellable>>
;;                   #V<callback: POINTER> #V<user_data: POINTER>): (#V<RETURN-VALUE: VOID>)>

(get-method-desc (nget *wk* "WebView") "run_javascript_in_world")
;; => #F<run_javascript_in_world(#V<script: STRING> #V<world_name: STRING>
;;                           #V<cancellable: #O<Cancellable>>
;;                           #V<callback: POINTER> #V<user_data: POINTER>): (#V<RETURN-VALUE: VOID>)>

(get-method-desc (nget *wk* "WebView") "run_javascript_finish")
;; => #F<run_javascript_finish(#V<result: I<AsyncResult>>): (#V<RETURN-VALUE: #S<JavascriptResult>>)>

(get-method-desc (nget *wk* "JavascriptResult")"get_js_value")
;; => #F<get_js_value(): (#V<RETURN-VALUE: #O<Value>>)>

(list-methods-desc (nget *jsc* "Value"))
(list-methods-desc (nget *jsc* "Context"))
||#

(defvar $js-result nil)

(defun eval-javascript-finish (source async-result)
  (let ((result
	 (handler-case (invoke (source "run_javascript_finish")
			 async-result)
	   (error (c)
	     (g-warning "Error Executing javacript")
	     (cl-user::write-lisp-backtrace c)
	     (g-warning "condition  = ~A" c)
	     nil))))
    (when result
      (let* ((value (invoke (result "get_js_value")))
	     (str-value (progn
			  (g-message "value = ~S" value)
			  (invoke (value "to_string"))))
	     (context (invoke (value "get_context")))
	     (exception (invoke (context "get_exception"))))
	(setq $js-result result)
	(cond (exception
	       (g-warning "Error Running Javascript: ~a"
			  (invoke (exception "get_message"))))
	      (t (g-message "Script result: ~a bytes~&" (length str-value))))))))

(defvar $ejsf-cb (gir-lib::register-callback #'eval-javascript-finish))

#+nil
(gir-lib::unregister-callback $ejsf-cb)

(defun eval-javascript (web-view string)
  (let* ((settings (invoke (web-view "get_settings")))
	 (orig (property settings "enable-javascript")))
    (unless orig
      (setf (property settings "enable-javascript") t))
    (invoke (web-view "run_javascript")
      string
      nil
      (cffi:callback gir-lib::funcall-object-async-ready-callback)
      $ejsf-cb)
    (unless orig
      (setf (property settings "enable-javascript") nil))))

;; has to be called on the mainthread so via with-gtk-thread. return
;; value is not useful
(defun eval-javascript-sync (web-view string)
  (let* ((contents)
	 (main-loop (invoke (*glib* "MainLoop" "new") nil nil))
	 (settings (invoke (web-view "get_settings")))
	 (orig (property settings "enable-javascript")))
    (flet ((finish (source async-result)
	     (let ((result
		    (handler-case (invoke (source "run_javascript_finish")
					  async-result)
		      (error (c)
			(g-warning "Error Executing javacript")
			(cl-user::write-lisp-backtrace c)
			nil))))
	       (when result
		 (g-message "result = ~S" result)
		 (let* ((value (invoke (result "get_js_value")))
			(str-value (progn
				     (g-message "value = ~S" value)
				     (invoke (value "to_string"))))
			(context (invoke (value "get_context")))
			(exception (invoke (context "get_exception"))))
		   (cond (exception
			  (g-warning "Error Running Javascript: ~a"
				     (invoke (exception "get_message"))))
			 (t (setq contents result)
			    (g-message "Script result: ~a~&" str-value))))))
	     (invoke (main-loop "quit"))))

      (gir-lib:with-registered-callback (loc)
	#'finish
	(unless orig
	  (setf (property settings "enable-javascript") t))
	(invoke (web-view "run_javascript")
		string
		nil
		(cffi:callback gir-lib::funcall-object-async-ready-callback)
		loc)
	(unless orig
	  (setf (property settings "enable-javascript") nil))
	(invoke (main-loop "run")))
      contents)))



;;; ----------------------------------------------------------------------
;;;
;;;
;;;
(defun jsc-value-get-type (obj)
  (macrolet ((gencond (obj)
	       (check-type obj symbol)
	       (let ((types '(array array_buffer boolean constructor function null number object string typed_array undefined)))
		 (loop for sym in types
		       collect `((invoke (,obj ,(concatenate 'string "is_" (string-downcase sym))))
				 ',sym)
		       into clauses
		       finally (return `(cond ,@clauses))))))
    (gencond obj)))

(export 'jsc-value-get-type)