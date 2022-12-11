#include <glib-unix.h>
#include <ecl/ecl.h>
#include "eclplug.h"
#define APP "eclplugtest"

gboolean global_quit_main_p = FALSE;

gboolean
handle_ctrl_c(gpointer user_data)
{
  g_message("Ctrl-c: quitting mainloop");
  global_quit_main_p = TRUE;
  g_main_context_wakeup(NULL);
  return G_SOURCE_REMOVE;
}

int
main (int argc, char **argv)
{

  ecl_initialize (argc > 1 ? argv[1] : APP);

  GSource *source = g_unix_signal_source_new (SIGINT);
  // fixme: this is basically wrong because mkcl wants to handle INT
  // to get into the debugger and we are hijacking C-c to quit the
  // process.
  g_source_set_callback (source, handle_ctrl_c, NULL, NULL);
  int quit_handler = g_source_attach (source, NULL);

  g_message("entering main loop");
  while (!global_quit_main_p)
    g_main_context_iteration(NULL, TRUE);
  g_message("exited main loop");
  return ecl_shutdown ();
}
