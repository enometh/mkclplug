#include <gio/gio.h>
#include "monitorlib.h"

struct watched
{
  char *filepath;
  GFileMonitor *gm;
  int tag;
  watchedcb_t watchedcb;
};

static void
monitorcb (GFileMonitor * gm, GFile * file, GFile * other_file,
	   GFileMonitorEvent event, gpointer user_data)
{
  struct watched *tmp = user_data;
  if (event != G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT &&
      event != G_FILE_MONITOR_EVENT_DELETED)
    return;
  const char *f = g_file_peek_path(file);
  g_message("MONITORCB  tmp->filepath = %s, GFile.path = %s",
	    tmp->filepath, f);
  g_return_if_fail (tmp);
  g_return_if_fail (tmp->filepath);
  if (tmp->watchedcb) {
    if (strcmp (f,tmp->filepath) == 0) {
      tmp->watchedcb (tmp->filepath);
    }
}
}

static struct watched *
monitor (char *filepath, watchedcb_t watchedcb)
{
  GFile *gf = g_file_new_for_path (filepath);
  GError *error = NULL;
  GFileMonitor *gm =
    g_file_monitor_file (gf, G_FILE_MONITOR_NONE, NULL, &error);
  if (error)
    {
      g_warning ("g_file_monitor_file(%s): failed returning 0x%p: %s",
		 filepath, gm, error->message ? : "");
      g_object_unref (gf);
      return NULL;
    }
  struct watched *tmp = g_new0 (struct watched, 1);
  if (!tmp)
    {
      g_object_unref (gm);
      g_object_unref (gf);
      return NULL;
    }
  tmp->gm = gm;
  tmp->filepath = strdup (filepath);
  tmp->watchedcb = watchedcb;
  tmp->tag = g_signal_connect (gm, "changed", G_CALLBACK (monitorcb), tmp);
  if (!(tmp->tag > 0))
    {
      g_debug
	("g_signal_connect: to the changed signal for FileMonitor for %s failed\n",
	 filepath);
      g_free (tmp->filepath);
      g_object_unref (gm);
      g_object_unref (gf);
      return NULL;
    }
  g_object_unref (gf);
  return tmp;
}

static void
unmonitor (struct watched *tmp)
{
  if (tmp)
    {
      if (tmp->gm)
	{
	  g_file_monitor_cancel (tmp->gm);
	  g_object_unref (tmp->gm);
	}
      // deallocate filepath
      if (tmp->filepath)
	g_free (tmp->filepath);
    }
}

void
load_and_monitor (char *lispfilepath, watchedcb_t watchedcb, gboolean unwatch)
{
  static GHashTable *watched = NULL;
  if (unwatch && !watched)
    {
      g_debug ("load_and_monitor_unwatch(%s): nothing is watched\n",
	       lispfilepath);
      return;
    }
  char *realfilepath = realpath (lispfilepath, NULL);
  if (!realfilepath)
    {
      g_debug ("load_and_monitor(%s): realpath failed: %s\n",
	       lispfilepath, g_strerror (errno));
    }
  char *key = realfilepath ? : lispfilepath;

  if (unwatch)
    {
      struct watched *tmp = g_hash_table_lookup (watched, key);
      if (!tmp)
	{
	  g_debug ("load_and_monitor_unwatch(%s): no key\n", key);
	}
      else
	{
	  g_debug ("load_and_monitor_unwatch(%s)\n", key);
	  unmonitor (tmp);
	  g_hash_table_remove (watched, key);
	}
      if (realfilepath)
	g_free (realfilepath);
      if (tmp)
	g_free(tmp);
      return;
    }
  if (!watched)
    watched = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
  struct watched *tmp = g_hash_table_lookup (watched, key);
  if (tmp)
    {
      g_debug ("load_and_monitor(%s): already monitored\n", key);
    }
  else
    {
      tmp = monitor (key, watchedcb);
      if (tmp)
	{
	  g_hash_table_replace (watched, strdup(key), tmp);
	  if (realfilepath)
	    {
	      if (tmp->watchedcb)
		tmp->watchedcb (tmp->filepath);
	    }
	  else
	    {
	      g_debug
		("load_and_monitor(%s): not loading non-existent file\n",
		 key);
	    }
	}
      else
	{
	  g_debug ("load_and_monitor(%s): failed to monitor\n", key);
	}
    }
  if (realfilepath)
    g_free (realfilepath);
}
