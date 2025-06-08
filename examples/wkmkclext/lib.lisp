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
   "$JS-RESULT"
   "$JS-VALUE"))
(in-package "WKMKCLEXTLIB")

;; the functions in this file should eventually end up in girlib-wk
(require 'girlib-wk)

#+nil
(mapcar (lambda (x) (unintern x "WKMKCLEXTLIB"))
	'(*wk* *wkext* *jsc*))

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

(get-method-desc (nget *wk* "WebView") "evaluate_javascript")
;; #F<evaluate_javascript(#V<script: STRING> #V<length: INTEGER>
;;                        #V<world_name: STRING> #V<source_uri: STRING>
;;                        #V<cancellable: #O<Cancellable>> #V<callback: POINTER>
;;                        #V<user_data: POINTER>): (#V<RETURN-VALUE: VOID>)>

(get-method-desc (nget *wk* "WebView") "evaluate_javascript_finish")
;; #F<evaluate_javascript_finish(#V<result: I<AsyncResult>>): (#V<RETURN-VALUE: #O<Value>>)>


||#

(defvar $js-result nil)

(defvar $js-value nil)

(defvar *43-api* t)

(defun eval-javascript-finish (source async-result)
  (let ((result
	 (handler-case (if *43-api*
			   (invoke (source "evaluate_javascript_finish")
			     async-result)
			   (invoke (source "run_javascript_finish")
			     async-result))
	   (error (c)
	     (g-warning "Error Executing javacript")
	     (cl-user::write-lisp-backtrace c)
	     (g-warning "condition  = ~A" c)
	     nil))))
    (when result
      (let* ((value (if *43-api* result (invoke (result "get_js_value"))))
	     (str-value (progn
			  (g-message "value = ~S" value)
			  (invoke (value "to_string"))))
	     (context (invoke (value "get_context")))
	     (exception (invoke (context "get_exception"))))
	(progn (if (not *43-api*) (setq $js-result result))
	       (setq $js-value result))
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
    (if *43-api*
	(invoke (web-view "evaluate_javascript")
	  string
	  -1
	  nil
	  nil
	  nil
	  (cffi:callback gir-lib::funcall-object-async-ready-callback)
	  $ejsf-cb)
	(invoke (web-view "run_javascript")
	  string
	  nil
	  (cffi:callback gir-lib::funcall-object-async-ready-callback)
	  $ejsf-cb))
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
		    (handler-case (if *43-api*
				      (invoke (source "evaluate_javascript_finish")
					async-result)
				      (invoke (source "run_javascript_finish")
					  async-result))
		      (error (c)
			(g-warning "Error Executing javacript")
			(cl-user::write-lisp-backtrace c)
			nil))))
	       (when result
		 #+nil
		 (g-message "result = ~S" result)
		 (let* ((value (if *43-api*
				   result
				   (invoke (result "get_js_value"))))
			(str-value (progn
				     #+nil
				     (g-message "value = ~S" value)
				     (invoke (value "to_string"))))
			(context (invoke (value "get_context")))
			(exception (invoke (context "get_exception"))))
		   (cond (exception
			  (g-warning "Error Running Javascript: ~a"
				     (invoke (exception "get_message"))))
			 (t (setq contents result)
			    (g-message "script result length = ~d~&" (length str-value))
			    #+nil
			    (g-message "Script result: ~a~&" str-value)))))
	       (progn (if (not *43-api*) (setq $js-result result))
		      (setq $js-value result)))
	     (invoke (main-loop "quit"))))

      (gir-lib:with-registered-callback (loc)
	#'finish
	(unless orig
	  (setf (property settings "enable-javascript") t))
	(if *43-api*
	    (invoke (web-view "evaluate_javascript")
	      string
	      -1
	      nil
	      nil
	      nil
	      (cffi:callback gir-lib::funcall-object-async-ready-callback)
	      loc)
	    (invoke (web-view "run_javascript")
	      string
	      nil
	      (cffi:callback gir-lib::funcall-object-async-ready-callback)
	      loc))
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

(defun jsc-value-get-object-class-name (obj)
  (when (eq 'object (jsc-value-get-type obj))
    (when (invoke (obj "object_has_property") "constructor")
      (let ((con (invoke (obj "object_get_property") "constructor")))
	(when (invoke (con "object_has_property") "name")
	  (let ((nam (invoke (con "object_get_property") "name")))
	    (invoke (nam "to_string"))))))))

(export '(jsc-value-get-type jsc-value-get-object-class-name))


(defun jsc-value-to-lisp (obj &key (number-type 'double) (default-json-p t))
  (let ((type (jsc-value-get-type obj)) found (second-ret t))
    (values
     (cond ((setq found (car (member type '(boolean string))))
	    (invoke (obj (format nil "to_~(~a~)" found))))
	   ((eql type 'number)
	    (check-type number-type (member double int32))
	    (invoke (obj (format nil "to_~(~a~)" number-type))))
	   (default-json-p (invoke (obj "to_json") 2))
	   ((eql type 'undefined) 'undefined)
	   (t (setq second-ret nil)
	      obj))
     second-ret)))

;;; ----------------------------------------------------------------------
;;;
;;; ;madhu 250117 - collect soup headers
;;;
;;;

;; provide this via girlib-wk
(eval-when (load eval compile)
(defvar *soup* (gir:require-namespace "Soup" "3.0"))
)

(defun hdrs (webview &key (tahp :response))
  "Tahp can be :response or :request"
  (let* ((main-resource (gir:invoke (webview "get_main_resource")))
	 (res (gir:property main-resource (ecase tahp
					    (:response "response")
					    (:request "request")))))
    (gir:invoke (res "get_http_headers"))))

(cffi:defcstruct (messages-header-iter :size #.(struct-info-get-size (info-of (nget *soup* "MessageHeadersIter")))))

#+nil
(= 24 (cffi:foreign-type-size '(:struct messages-header-iter)))

(defun collect-headers (hdrs)
  (cffi:with-foreign-object (msg-hdr-iter-ptr '(:struct messages-header-iter))
    (let ((msg-hdr-iter  (gir::build-struct-ptr
		       (nget *soup* "MessageHeadersIter")
		       msg-hdr-iter-ptr)))
      (cffi:foreign-funcall "soup_message_headers_iter_init"
	:pointer msg-hdr-iter-ptr
	:pointer (this-of hdrs)
	:void)
      (loop for  (ret key val) =
	    (multiple-value-list (invoke (msg-hdr-iter "next")))
	    while ret
	    collect (cons key val)))))
#||
(collect-headers
 (gir-lib:block-idle-add (hdrs (wyeb-user::wv) :tahp :response)))
||#

(export '(hdrs collect-headers))


;;; ----------------------------------------------------------------------
;;;
;;; ;madhu 250515 collect soup cookies
;;;

(defun get-cookie-accept-policy (cookie-mgr)
  (gir-lib:block-idle-add
    (call-with-async-ready-callback cookie-mgr "get_accept_policy")))

(defun filter-soup-cookies (cookies domain)
  "return only those SoupCookie cookies that match string domain."
  (remove-if-not (lambda (c)
		   (search domain (gir:invoke (c "get_domain"))))
		 cookies))

(defun all-cookies-soup
    (soup-cookie-jar-path &key
     match-domain
     (storage-type (cond ((user::suffixp ".txt" soup-cookie-jar-path)
			       "CookieJarText")
			      ((user::suffixp ".sqlite" soup-cookie-jar-path)
			       "CookieJarDB")
			      (t (error "supply CookieJarText or CookieJarDB as storage-type")))))
  (let (cookie-jar cookies-ptr cookies)
    (when (and (setq cookie-jar
		     (gir:invoke (*soup* storage-type "new")
		       soup-cookie-jar-path t))
	       (setq cookies-ptr
		     (invoke (cookie-jar "all_cookies")))
	       (not (cffi:null-pointer-p cookies-ptr))
	       (setq cookies
		     (list->objects cookies-ptr (nget *soup* "Cookie"))))
      (if match-domain
	  (filter-soup-cookies cookies match-domain)
	  cookies))))

(defun all-cookies (cookie-manager &key match-domain)
  (let* ((ptr (block-idle-add
		(call-with-async-ready-callback
		 cookie-manager
		 "get_all_cookies")))
	 (cookies
	  (unless (cffi:null-pointer-p ptr)
	    (list->objects ptr (nget *soup* "Cookie")))))
    (if match-domain
	(filter-soup-cookies cookies match-domain)
	cookies)))

(defun cookies-matching (cm uri)
  (let ((ptr (block-idle-add
	       (call-with-async-ready-callback
		cm
		"get_cookies"
		:args (list uri)))))
    (unless (cffi:null-pointer-p ptr)
      (list->objects ptr (nget *soup* "Cookie")))))


(export '(get-cookie-accept-policy all-cookies-soup all-cookies
	  cookies-matching))

#||
(setq $wv (wyeb-user::wv))
(setq $cm (invoke ((property $wv "web-context") "get_cookie_manager")))
(all-cookies $cm)
(mapcar (lambda (c)
	  (cons (invoke (c "get_domain"))
		(invoke (c "to_cookie_header"))))
	(all-cookies $cm :match-domain "stackoverflow"))
(setq $a (all-cookies-soup "/dev/shm/cookies.txt" :match-domain "stackoverflow"))
(block-idle-add
  (mapcar (lambda (cookie)
	    (call-with-async-ready-callback
	     $cm "add_cookie"
	     :args (list cookie)))
	  $a))
(block-idle-add
  (mapcar (lambda (cookie)
	    (call-with-async-ready-callback
	     $cm "delete_cookie"
	     :args (list cookie)))
	  $a))
||#


;;; ----------------------------------------------------------------------
;;;
;;; Settings
;;;

(defun dump-settings-to-file (settings output-file)
  (let ((new (invoke (*glib* "KeyFile" "new"))))
    (loop for (k . v) in  (gir::list-props settings)
	  do (etypecase v
	       (boolean
		(invoke (new "set_boolean") "websettings" k v))
	       (string
		(invoke (new "set_string") "websettings" k v))
	       (integer
		(unless (equal k "hardware-acceleration-policy")
		  (invoke (new "set_integer") "websettings" k v)))))
    (invoke (new "save_to_file") output-file)))

(export 'dump-settings-to-file)


;;; ----------------------------------------------------------------------
;;;
;;; Settings: Features
;;;

#||
(nget *wk* "FeatureList")
(nget *wk* "Settings" "get_all_features")
(list-class-functions-desc (nget *wk* "Settings"))
||#

(defvar +wk-feature-slots+
  '(category default-value details identifier name status))

(defun feature->plist (wk-feature)
  (mapcar (lambda (slot)
	    (list (intern (symbol-name slot) :keyword)
		  (invoke (wk-feature (concatenate 'string "get_" (gir::c-name slot))))))
	  +wk-feature-slots+))

(defmacro with-feature-slots ((&rest slot-bindings) feature &body body)
  (let* ((feature-var (gensym))
	 (binds-1 ;; slot-bindngs == (slot-name) or ((var slot-name))
	  (loop for elt in slot-bindings collect
	       (let (slot-name var-name)
		 (etypecase elt
		   (atom (setq slot-name elt var-name elt))
		   (cons (setq slot-name (cadr elt) var-name (car elt))
			 (assert (null (cddr elt)))))
		 (check-type var-name symbol)
		 (check-type slot-name symbol)
		 (assert  (find (symbol-name slot-name) +wk-feature-slots+
				:test #'equal :key #'symbol-name))
		 (list var-name `(gir:invoke (,feature-var ,(concatenate 'string "get_" (gir::c-name slot-name)))))))))
    `(let* ((,feature-var ,feature)
	   ,@binds-1)
       ,@body)))

#+nil
(with-feature-slots ((cat category) details) x (list cat details))

(defun get-feature-list (flag)
  (invoke (*wk* "Settings" (ecase flag
			     (:exp "get_experimental_features")
			     (:dev "get_development_features")
			     (:all "get_all_features")))))

(defun map-feature-list (fn feature-list &key return-type)
  (etypecase feature-list
    (gir::struct-instance nil)
    (keyword (setq feature-list (get-feature-list feature-list))))
  (let* ((ret (cons t nil))
	 (tail ret)
	 (len (invoke (feature-list "get_length"))))
    (loop for i below len
	  for feature = (invoke (feature-list "get") i)
	  for result = (funcall fn feature)
	  if return-type do (let ((new-cons (cons result nil)))
			      (setf (cdr tail) new-cons)
			      (setq tail new-cons)))
    (if return-type (coerce (cdr ret) return-type))))

#+nil
(block-idle-add
  (time (map-feature-list 'feature->plist :exp :return-type 'list)))

#+nil
(block-idle-add
  (setq $all-names
   (map-feature-list (lambda (feature)
		       (with-feature-slots (name) feature
			 name))
		     :dev
		     :return-type 'list)))

(export '(get-feature-list
	  with-feature-slots
	  map-feature-list
	  feature->plist))
