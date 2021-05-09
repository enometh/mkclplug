#include <gmodule.h>
#include <mkcl/mkcl.h>
#include "mkclplug.h"

extern void init_wkmkclext (MKCL, mkcl_object, mkcl_object);

const char *
g_module_check_init (GModule * module)
{
  g_message ("g_module_check_init(%s):", g_module_name (module));
  void *loc;
  if (!g_module_symbol (module, "init_wkmkclext", &loc))
    {
      return "failed to provide init_wkmkclext";
    }
  mkcl_initialize_module ("wkmkclext", init_wkmkclext);
  return NULL;
}
