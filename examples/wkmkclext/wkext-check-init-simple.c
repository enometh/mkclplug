#include <gmodule.h>
const char *
g_module_check_init (GModule * module)
{
  g_message ("g_module_check_init(%s):", g_module_name (module));
  return NULL;
}
