; wkmkclext/dbus-backdoor.lisp
(in-package "WKMKCLEXTEXT")
(require 'girlib)

(defvar $eval-server
  (let* ((pid (gir-lib::getpid))
	 (server
	  (make-instance 'gdbus:dbus-service
	    :interface-name "code.girlib.EvalServer"
	    :node-info gdbus::$eval-server-introspection-xml
	    :method-handlers
	    `(("Eval" . gdbus::eval-server-eval))
	    :bus-name (format nil "code.girlib.wkmkclext.id~D" pid)
	    :object-path (format nil "/code/wkmkclext/~D" pid)
	    )))
    (gdbus:register server)
    (gdbus:bus-name (slot-value server 'gdbus:bus-name) :own)
    server))

#||
(gdbus:register $eval-server)
(gdbus:unregister $eval-server)
(gdbus:bus-name (slot-value $eval-server 'gdbus:bus-name) :own)
(gdbus:bus-name (slot-value $eval-server 'gdbus:bus-name) :unown)

eval $(busctl --user 2>/dev/null | grep code.girlib.wkmkclext | read busname pid name user dest unit session description ; echo  busctl --user introspect $busname  "/code/wkmkclext/$pid" code.girlib.EvalServer)

eval $(busctl --user 2>/dev/null | grep code.girlib.wkmkclext | read busname pid name user dest unit session description ; echo  busctl --user call $busname  "/code/wkmkclext/$pid" code.girlib.EvalServer Eval s "'(+ 2 3)'")
eval $(busctl --user 2>/dev/null | grep code.girlib.wkmkclext | read busname pid name user dest unit session description ; echo  busctl --user call $busname  "/code/wkmkclext/$pid" code.girlib.EvalServer Eval s "'(write *package*)'")

eval $(busctl --user 2>/dev/null | grep code.girlib.wkmkclext | read busname pid name user dest unit session description ; echo  busctl --user call $busname  "/code/wkmkclext/$pid" code.girlib.EvalServer Eval s "'(load\"~/sly-config.lisp\")'")

eval `busctl --user 2>/dev/null | grep code.girlib.wkmkclext | read busname pid name user dest unit session description ; echo  gdbus call --session --dest $dest --object-path "/code/wkmkclext/$pid" --method "code.girlib.EvalServer.Eval" "'(progn(load\"~/sly-config.lisp\")(cl-user::slynk-start))'"`
||#


#||
;;; Or launch it with another lisp
(defpackage "DBUS-BACKDOOR-USER" (:use "CL" "GIR" "GIR-LIB" "GDBUS"))
(in-package "DBUS-BACKDOOR-USER")

(setq $fdbo (make-instance 'dbus-base-object
	      :bus (dbus-session-bus)
	      :bus-name "org.freedesktop.DBus"))
(setq $p (make-dbus-proxy-for-interface $fdbo "org.freedesktop.DBus"))
(progn
(setq $ret (proxy-call-sync $p "ListNames" nil :timeout-msec 10))
(setq $ret (remove-if-not (lambda (x) (search "code.girlib.wkmkclext" x)) $ret))
(setq $pids (map 'list
		 (lambda (name)
		   (proxy-call-sync $p "GetConnectionUnixProcessID"
			 (list name)))
		 $ret))
)
(setq $pid (car $pids))
(setq $wkdbo (make-instance 'dbus-base-object
	       :bus (dbus-session-bus)
	       :bus-name (format nil "code.girlib.wkmkclext.id~D" $pid)
	       :object-path (format nil "/code/wkmkclext/~D" $pid)))
(setq $wkp (make-dbus-proxy-for-interface $wkdbo "code.girlib.EvalServer"))


(proxy-call-sync $wkp "Eval" '("(load \"~/sly-config.lisp\")") :timeout-msec 2000)
(proxy-call-sync $wkp "Eval" (list "(ignore-errors (cl-user::slynk-start))") :timeout-msec 20000)

(lisp-implementation-version)
(slynk::lisp-implementation-program)
(get-method-names $p)
(get-method-signature $p "ListNames" :names-p t)
(get-method-signature $p "ListNames" )
(get-method-signatureq $p "GetConnectionUnixProcessID" )
(setq $ret (proxy-call-sync $p "ListNames" nil :timeout-msec 10))
(setq $ret (remove-if-not (lambda (x) (search "code.girlib.wkmkclext" x)) $ret))
(setq $pids (map 'list
		 (lambda (name)
		   (proxy-call-sync $p "GetConnectionUnixProcessID"
			 (list name)))
		 $ret))
(setq $pid (car $pids))
(get-method-signature $wkp "Eval")
||#