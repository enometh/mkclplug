#include <gmodule.h>
#include <ecl/ecl.h>
#include "eclplug.h"

extern void init_wkeclext (cl_object);

const char *
g_module_check_init (GModule * module)
{
  g_message ("g_module_check_init(%s):", g_module_name (module));
  void *loc;
  if (!g_module_symbol (module, "init_wkeclext", &loc))
    {
      return "failed to provide init_wkeclext";
    }
  ecl_initialize_module ("wkeclext", init_wkeclext);
  return NULL;
}
