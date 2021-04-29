#include <mkcl/mkcl.h>
#include "mkclplug.h"
#define APP "mkclplugtest"

int
main (int argc, char **argv)
{
  mkcl_initialize (APP);
  mkcl_repl ();
  return mkcl_shutdown ();
}
