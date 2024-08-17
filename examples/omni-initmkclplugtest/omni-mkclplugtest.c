#include <glib-unix.h>
#include <stdio.h>

#if defined(OMNI_ECL) || defined(OMNI_MKCL)
#include "omni-initmkclplug.h"
#endif

#if defined(OMNI_ECL) || defined(OMNI_MKCL)
#define OVERRIDE_STATIC
#endif

// BEGIN_STATIC_OVERRIDES
#ifdef OVERRIDE_STATIC
#define static __attribute__((visibility("default")))
#endif

static void usage(void);
static gboolean handle_ctrl_c(gpointer);
static gboolean global_quit_main_p;

gboolean global_quit_main_p = FALSE;

gboolean
handle_ctrl_c(gpointer user_data)
{
  g_message("Ctrl-c: quitting mainloop");
  global_quit_main_p = TRUE;
  g_main_context_wakeup(NULL);
  return G_SOURCE_REMOVE;
}

void
usage(void)
{
	fprintf(stderr, "usage:\n");
}

// END_STATIC_OVERRIDDES
#ifdef OVERRIDE_STATIC
#undef static
#endif

int
main()
{
#if defined(OMNI_ECL) || defined(OMNI_MKCL)
	initmkclplug(0,0);
#endif

  GSource *source = g_unix_signal_source_new (SIGINT);
  g_source_set_callback (source, handle_ctrl_c, NULL, NULL);
  int quit_handler = g_source_attach (source, NULL);

  g_message("entering main loop");
  while (!global_quit_main_p)
    g_main_context_iteration(NULL, TRUE);
  g_message("exited main loop");
}
/*
(export PKG_CONFIG_PATH=$(pwd); gcc omni-mkclplugtest.c $(pkg-config --cflags --libs eclplug-1 mkclplug-1 gio-2.0) -ldl  -fPIC -DOMNI_ECL -DOMNI_MKCL)

(export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig; c99 -c omni-mkclplugtest.c -fPIC -DPIC -DOMNI_ECL -DOMNI_MKCL -I.. -D_DEFAULT_SOURCE -fvisibility=default $(pkg-config --cflags eclplug-1 mkclplug-1 gio-2.0))

(export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig; c99 -fPIC -c omni-mkclplugtest.c -fPIC -DOMNI_ECL -DOMNI_MKCL -I.. -D_DEFAULT_SOURCE -fvisibility=default $(pkg-config --cflags eclplug-1 mkclplug-1 gio-2.0))
(export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig; c99 -o a.out omni-mkclplugtest.o $(pkg-config --libs eclplug-1 mkclplug-1 gio-2.0))
objdump -T a.out
*/