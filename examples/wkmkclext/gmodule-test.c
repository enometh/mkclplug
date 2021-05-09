#include <glib-unix.h>
#include <gmodule.h>
#include <glib.h>

static gboolean
handle_ctrl_c(gpointer user_data)
{
  g_main_loop_quit ((GMainLoop*) user_data);
  g_message("quitting main");

}

int
main(int argc, char **argv)
{
  char *name;
  GSList *modules_list = NULL;

  g_setenv("G_DEBUG", "resident-modules bind-now-modules", TRUE);
  g_setenv("G_MESSAGES_PREFIXED", "all", TRUE);
  g_setenv("G_MESSAGES_DEBUG", "all", TRUE);

  while (--argc) {
    GModule *module = g_module_open(name=*++argv, 0);
    if (module == NULL) {
      g_warning("Did not open %s", name);
    } else
      modules_list = g_slist_append(modules_list, module);
  }

  g_message("opened %d modules", g_slist_length(modules_list));




  GMainLoop *loop = g_main_loop_new(NULL, 0);
  GSource *source = g_unix_signal_source_new (SIGINT);
  // fixme: this is basically wrong because mkcl wants to handle INT
  // to get into the debugger and we are hijacking C-c to quit the
  // process.
  g_source_set_callback (source, handle_ctrl_c, loop, NULL);
  int quit_handler = g_source_attach (source, NULL);

  g_main_loop_run(loop);
  return 0;
}

/*
gcc -ggdb gmodule-test.c $(pkg-config --cflags --libs gmodule-2.0)
*/