;;; -*- Mode: LISP; Package: :cl-user; BASE: 10; Syntax: ANSI-Common-Lisp; -*-
;;;
;;;   Time-stamp: <2022-12-10 17:48:39 IST>
;;;   Touched: Sat Dec 10 15:50:46 2022 +0530 <enometh@net.meer>
;;;   Bugs-To: enometh@net.meer
;;;   Status: Experimental.  Do not redistribute
;;;   Copyright (C) 2022 Madhu.  All Rights Reserved.
;;;
(defpackage "WKMKCLEXTLIB"
  (:use "CL" "GIR-LIB" "GIR")
  (:export "*WK*" "*WKEXT*"
   "WEB-VIEW"
   "WEB-CONTEXT"
   "WEB-EXTENSION"
   "WEB-PAGE"
   "DEFINE-USER-MESSAGE-HANDLER-FOR"))
(in-package "WKMKCLEXTLIB")

(defvar *wk* (gir:require-namespace "WebKit2" "4.1"))
(defvar *wkext* (gir:require-namespace "WebKit2WebExtension" "4.1"))

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
