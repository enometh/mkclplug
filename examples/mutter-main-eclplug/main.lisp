(in-package "MUTTER-MAIN-ECLPLUG")
(in-package "GIR-TEST")

(defvar $mutter-libdir
  (merge-pathnames "usr/lib64/mutter-10"
		   (translate-logical-pathname "HOME:root;")))


(invoke(*gi-repository* "Repository" "prepend_search_path")
       (namestring $mutter-libdir))
(invoke(*gi-repository* "Repository" "prepend_library_path")
       (namestring $mutter-libdir))

#+nil
(list->strings(invoke(*gi-repository* "Repository" "get_search_path")))

(defvar *meta* (require-namespace "Meta" "10"))
(defvar *cogl* (require-namespace "Cogl"))
(defvar *clutter* (require-namespace "Clutter"))



