#include <glib-unix.h>
#include <mkcl/mkcl.h>
#include "mkclplug.h"
#define APP "mkclplugtest"

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
  mkcl_initialize (APP);

  GSource *source = g_unix_signal_source_new (SIGINT);
  // fixme: this is basically wrong because mkcl wants to handle INT
  // to get into the debugger and we are hijacking C-c to quit the
  // process.
  g_source_set_callback (source, handle_ctrl_c, NULL, NULL);
  int quit_handler = g_source_attach (source, NULL);

  g_message("entering main loop");

  MKCL = MKCL_ENV();
  MKCL_CATCH_ALL_BEGIN (env)
  {
    MKCL_SETUP_CALL_STACK_ROOT_GUARD (env);
    mkcl_enable_interrupts (env);
    {

  while (!global_quit_main_p)
    g_main_context_iteration(NULL, TRUE);
  g_message("exited main loop");
  env->own_thread->thread.result_value = mk_cl_Cnil;

    }
    MKCL_UNSET_CALL_STACK_ROOT_GUARD (env);
  } MKCL_CATCH_ALL_IF_CAUGHT
  {
    MKCL_UNSET_CALL_STACK_ROOT_GUARD (env);
    /* some other late cleanup should go here. */
  } MKCL_CATCH_ALL_END;

  return mkcl_shutdown ();
}
