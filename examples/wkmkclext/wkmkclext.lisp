(in-package "WKMKCLEXTEXT")

(declaim (optimize (debug 0)))
;; madhu 210502 otherwise our cffi export-p mechanism with mkcl's
;; c-export-name doesn't work

(defvar +wkmkclext-simple-feature-present-p+ #+wkmkclext-simple t #-wkmkclext-simple nil)
(eval-when (load eval)
  (assert (eq +wkmkclext-simple-feature-present-p+
	      (load-time-value (find :wkmkclext-simple *features*)))
      nil "WKMKCLEXT-SIMPLE Feature ~:[absent~;present~] at compile time but ~:*~:[present~;absent~] at run time"
    +wkmkclext-simple-feature-present-p+))

(defvar *webext* (gir:require-namespace "WebKit2WebExtension"))

(defvar $this-extension nil)

(cffi:defcallback (webkit-web-extension-initialize
		   #-wkmkclext-simple :export-p
		   #-wkmkclext-simple t)
    :void
    ((WebKitWebExtension :pointer))
  (format t "Now playing: WebKitWebExtensionIntialize...~&")
  (let ((gobject (gir::build-object-ptr (gir:nget *webext* "WebExtension")
					WebKitWebExtension)))
    (setq $this-extension gobject)
    (gir:connect gobject "page-created"
		 #'(lambda (WebKitWebExtension WebKitWebPage)
		     (when (fboundp 'on-page-created)
		       (funcall 'on-page-created
				WebKitWebExtension WebKitWebPage))))
    (load (merge-pathnames "wkmkclext-dbus-backdoor.lisp"
			   cl-user::*wkmkclext-source-dir*))))

#+wkmkclext-simple
(cffi:foreign-funcall "register_init1" :pointer
		      (cffi:callback webkit-web-extension-initialize)
		      :void)

(defun on-page-created (WebKitWebExtension WebKitWebPage)
  (declare (ignorable WebKitWebExtension))
  (gir:connect WebKitWebPage "document-loaded"
	       #'(lambda (WebKitWebPage)
		   (when (boundp 'on-document-loaded)
		     (funcall 'on-document-loaded WebKitWebPage))))
  (gir:connect WebKitWebPage  "send-request"
	       #'(lambda (webpage request response)
		   (when (fboundp 'on-send-request)
		     (funcall 'on-send-request webpage request response)))))


#+nil
(gir:get-signal-desc (nget *webext* "WebPage") "send-request")