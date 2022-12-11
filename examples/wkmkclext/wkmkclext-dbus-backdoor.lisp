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