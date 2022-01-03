// alternative to not using export-cname.

#include <stdio.h>
#include <webkit2/webkit-web-extension.h>

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
	fprintf(stderr, WKEXT_APPNAME " initialize\n");
	if (init1) {
		init1(extension);
	} else {
	  g_warning("lisp side not initalized");
	}
}
