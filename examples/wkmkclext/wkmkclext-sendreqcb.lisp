(in-package "WKMKCLEXTEXT")

(defvar *send-request-hooks* nil)

;; boolean 0 accept 1 reject
(defun on-send-request (webpage request response)
  (progn ;ignoring-errors
    (let ((fromuri (gir:invoke (webpage "get_uri")))
	  (requri (gir:invoke (request "get_uri")))
	  (responseuri (and response (gir:invoke (response "get_uri"))))
	  (decide :ACCEPT)
	  _decide
	  (reason "unset")
	  _reason)
      (format t "~A~&"
	      (pairlis
	       '(fromuri requri responseuri webpage request response)
	       (list fromuri requri responseuri webpage request response)))
      (dolist (fun *send-request-hooks*)
	(format t "sendcb: RUNNING ~S~&" fun)
	(let ((failed t))
	  (ignoring-errors
	    (multiple-value-setq (_decide _reason)
	      (funcall fun fromuri requri responseuri webpage request response))
	    (setq failed nil))
	  (unless failed
	    (case _decide
	      ((:ACCEPT :REJECT :ACCEPT-UNCONDITIONAL)
	       (setq decide _decide reason _reason)
	       (format t "sendcb: ~S ~S~&" fun _decide)
	       (case _decide
		 ((:REJECT :ACCEPT-UNCONDITIONAL)
		  (return))))
	      (t
	       (format t "sendcb: ~S returns unknown value: ~S~&" fun _decide)
	       )))))
      (format t "send-request-cb: ~A FROM: ~S REQ: ~S~@[ RESPONSE: ~S~] REASON: ~S~&"
	      decide fromuri requri responseuri reason)
      (ecase decide
	(:ACCEPT nil)
	(:REJECT t)))))


;;; ----------------------------------------------------------------------
;;;
;;;  RUDIMENTARY JUNK FILTER - reject requests to google facebook
;;;  twitter
;;;

(defvar *junk-hosts* '("google.com" "facebook.com" "twitter.com"))

(defun host-string (http-url) http-url)
(defun junkbuster (fromuri requri responseuri webpage request response)
  (declare (ignorable fromuri requri responseuri webpage request response))
  (block checkwb
    (loop with host-string = (host-string requri)
	  for string in *junk-hosts*
	  do (format t "search ~A ~A~&" string host-string)
	  if (search string host-string)
	  do (return-from checkwb (values :REJECT "Junked Host")))
    (return-from checkwb (values :ACCEPT "Pass junkbuster"))))

(pushnew 'junkbuster *send-request-hooks*)
