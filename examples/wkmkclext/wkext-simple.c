// alternative to not using export-cname.

#include <stdio.h>
#include <webkit2/webkit-web-extension.h>

#ifdef WK_MKCL
#include <mkclplug.h>
void init_wkmkclext(MKCL, mkcl_object cblock, mkcl_object fasl_filename)
{
}
#ifdef WK_ECL
#error define one of WK_MKCL or WK_ECL
#endif
#endif

#ifdef WK_ECL
#include <eclplug.h>
void init_wkeclext(cl_object entry)
{
}
#ifdef WK_MKCL
#error define one of WK_MKCL or WK_ECL
#endif
#endif

void (*init1)(void *webkitwebextension) = NULL;
/*
 * (cffi:defcallback initialize-webextension :void ((webextension :pointer)))
 * (cffi:foreign-funcall "register_init1" :pointer
 *    (cffi:callback initialize-webextension) :void)
 */
void
register_init1(void (*func)(void *))
{
	init1 = func;
}

G_MODULE_EXPORT void
webkit_web_extension_initialize (WebKitWebExtension *extension)
{
	fprintf(stderr,
#ifdef WK_MKCL
		"wkmkclext"
#endif
#ifdef WK_ECL
		"wkeclext"
#endif
		" initialize\n");

	if (init1) {
		init1(extension);
	} else {
	  g_warning("lisp side not initalized");
	}
}
