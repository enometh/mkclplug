;; mutter-main-eclplug/dbus-backdoor.lisp
(in-package "MUTTER-MAIN-ECLPLUG")

(defvar $eval-server
  (let* ((pid (gir-lib::getpid))
	 (server
	  (make-instance 'gdbus:dbus-service
	    :interface-name "code.girlib.EvalServer"
	    :node-info gdbus::$eval-server-introspection-xml
	    :method-handlers
	    `(("Eval" . gdbus::eval-server-eval))
	    :bus-name (format nil "code.girlib.muttermaineclplug.id~D" pid)
	    :object-path (format nil "/code/muttermaineclplug/~D" pid)
	    )))
    (gdbus:register server)
    (gdbus:bus-name (slot-value server 'gdbus:bus-name) :own)
    server))

#||
(gdbus:register $eval-server)
(gdbus:unregister $eval-server)
(gdbus:bus-name (slot-value $eval-server 'gdbus:bus-name) :own)
(gdbus:bus-name (slot-value $eval-server 'gdbus:bus-name) :unown)
gdbus call --session --dest ":1.2717" --object-path "/code/muttermaineclplug/30229" --method "code.girlib.EvalServer.Eval" '(progn(slynk-start))'
||#