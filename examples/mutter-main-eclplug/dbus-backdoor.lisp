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
	    :bus-name (format nil "org.gnome.Mutter.Lisp")
	    :object-path (format nil "/eval")
	    )))
    (gdbus:register server)
    (gdbus:bus-name (slot-value server 'gdbus:bus-name) :own)
    server))

#||
(gdbus:register $eval-server)
(gdbus:unregister $eval-server)
(gdbus:bus-name (slot-value $eval-server 'gdbus:bus-name) :own)
(gdbus:bus-name (slot-value $eval-server 'gdbus:bus-name) :unown)
gdbus call --session --dest org.gnome.Mutter.Lisp --object-path /eval \
 --method "code.girlib.EvalServer.Eval" '(+ 2 3)'
gdbus call --session --dest org.gnome.Mutter.Lisp --object-path /eval \
 --method "code.girlib.EvalServer.Eval" '(slynk-start)'
||#