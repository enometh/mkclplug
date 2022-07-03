#include <mkcl/mkcl.h>
#include <mkcl/internal.h>
#include <glib.h>
#include "monitorlib.h"

// should never drop into debugger as it does not have the suitable
// framing that MKCL expects at the root of the callstack. Any error
// in the lisp form makes MKCL lose hard.
static mkcl_object
mkcl_call (MKCL, char *p)
{
  mkcl_object form = mkcl_fast_read_from_cstring (env, p);
  mkcl_object ret = mk_cl_eval (env, form);
  return ret;
}

static void
mkcl_initialize_disable_fpe (MKCL)
{
  const char *p;
  if (!(p = g_getenv("NODISABLEFPE")) || !(strcmp(p, "1") == 0 )) {
  mkcl_call (env, ("\
(progn\
  (si::disable-fpe t))"));
  }
}

static void
mkcl_initialize_write_lisp_backtrace (MKCL)
{
  static int initialized = 0;
  if (!initialized)
    {
      initialized = 1;
      mkcl_call (env, ("\
(defun cl-user::write-lisp-backtrace (condition)\
  (let* ((top (si:ihs-top))\
	 (stream *error-output*)\
         (repeats top)\
         (backtrace (loop :for ihs :from 0 :below top\
                          :collect (list (si::ihs-fun ihs)\
                                         (si::ihs-env ihs)))))\
    (format stream \"--------------------- BACKTRACE ----------------~&\")\
    (loop :for i :from 0 :below repeats\
          :for frame :in (nreverse backtrace) :do\
          (ignore-errors (format stream \"~&~D: ~S~%\" i frame)))\
    (ignore-errors (format stream \"condition: ~A~&\" condition))\
    (format stream \"-------------------------END--------------------~&\")\
    ))"));
    }
}

static void
mkcl_initialize_crock_debugger (MKCL)
{
  mkcl_initialize_write_lisp_backtrace (env);
  static int initialized = 0;
  if (!initialized)
    {
      initialized = 1;
      mkcl_call (env, ("\
(progn\
 (defvar cl-user::*original-debugger-hook* *debugger-hook*)\
 (defvar cl-user::*eval-successful-p* t)\
 (defun cl-user::safe-eval-debugger-hook (condition old-hook)\
   (declare (ignore old-hook))\
   (format t \"Entering safe-eval-debugger-hook~&\")\
   #+nil(si::tpl-backtrace)\
   (write-lisp-backtrace condition)\
   (setq cl-user::*eval-successful-p* nil)\
   (throw :catch-tag condition)))"));
    }
}

// should catch errors
void
mkcl_crock_call (MKCL, char *p)
{
  mkcl_object form, ret;
  mkcl_object tag = mkcl_fast_read_from_cstring (env, ":CATCH-TAG");
  MKCL_CL_CATCH_BEGIN (env, tag);
  mkcl_call (env, "\
(progn\
 (setq cl-user::*eval-successful-p* t)\
 (setq *debugger-hook* 'cl-user::safe-eval-debugger-hook))");
  form = mkcl_fast_read_from_cstring (env, p);
  MKCL_CL_CATCH_END;
  mkcl_call (env, "(setq *debugger-hook* cl-user::*original-debugger-hook*)");
  if (mkcl_fast_read_from_cstring (env, "CL-USER::*EVAL-SUCCESSFUL-P*") == mk_cl_Cnil)
    {
      g_warning ("eval: read failed");
      return;
    }
  MKCL_CL_CATCH_BEGIN (env, tag);
  mkcl_call (env, "\
(progn\
 (setq cl-user::*eval-successful-p* t)\
 (setq *debugger-hook* 'cl-user::safe-eval-debugger-hook))");
  ret = mk_cl_eval (env, form);
  MKCL_CL_CATCH_END;
  mkcl_call (env, "(setq *debugger-hook* cl-user::*original-debugger-hook*)");
  if (mkcl_fast_read_from_cstring (env, "CL-USER::*EVAL-SUCCESSFUL-P*") == mk_cl_Cnil)
    {
      g_warning ("eval: eval failed");
      return;
    }
}

static mkcl_env stashed_env;
char *stashed_appname;

// vararg safe eval
void
mkcl_eval (const char *fmt, ...)
{
  MKCL = stashed_env;

  char buf[74], *p = buf, *np;
  int n, size = sizeof (buf);;
  va_list ap;

  while (1)
    {
      va_start (ap, fmt);
      n = g_vsnprintf (p, size, fmt, ap);
      va_end (ap);

      if (n >= 0 && n < size)
	break;

      if (n < 0 || !(n < size))
	{
//                      fprintf(stderr, "eval: string too long: ");
	  if (n < 0)
	    {
	      size *= 2;
//                              fprintf(stderr, "malloc double size %d\n", size);
	    }
	  else
	    {
	      size = n + 1;
//                              fprintf(stderr, "malloc exact size %d\n", size);
	    }
	  if (p == buf)
	    p = NULL;
	  if ((np = realloc (p, size)) == NULL)
	    {
	      g_warning ("mkcl_eval: couldn't allocate memory: %s\n",
			 strerror (errno));
	      free (p);
	      return;		// ECL_NIL; // XXX
	    }
	  else
	    p = np;
	}
    }
  mkcl_crock_call (env, p);
  if (!(p == buf))
    free (p);
}

char *
initrc_pathname (const char *app)
{
  /* echo ~/.config/APP${SUFFIX:+.}${SUFFIX}/initrc.lisp */
  const char *envsuf = g_getenv ("SUFFIX");
  char *dirnam = g_strconcat (app, envsuf && *envsuf ? "." : "",
			      envsuf, NULL);
  char *initrc = g_build_filename (g_get_user_config_dir (), dirnam,
				   "initrc.lisp", NULL);
  g_free (dirnam);
  return initrc;
}

static void
loadlispfile (char *lispinitfile)
{
  g_assert (stashed_env);
  MKCL = stashed_env ; //MKCL_ENV();
  gint64 start1, stop1;
  g_debug ("loading %s\n", lispinitfile);
  start1 = g_get_monotonic_time ();
  mkcl_eval ("(let ((f \"%s\")) (and (probe-file f) (load f)))",
	     lispinitfile);
  stop1 = g_get_monotonic_time ();
  g_debug ("%s in %g seconds"
	   "= %" G_GINT64_FORMAT " - %" G_GINT64_FORMAT "\n",
	   lispinitfile, (stop1 - start1) / 1.0e6, stop1, start1);
}

static void
mkcl_initialize_boot (char *app)
{
  if (stashed_env)
    {
      g_error ("mkcl_initialize: ealready");
      return;
    }

  g_message("initializing app %s", app);
  stashed_appname = strdup(app);

  char *argv[] = { app, 0 };
  MKCL = mkcl_boot (1, argv, NULL);

  if (env == NULL)
    {
      g_error ("boot failed: %s", g_strerror (errno));
      return;
    }

  stashed_env = env;

  g_info ("initialize_mkcl: env = %p\n", env);
//      atexit(cl_shutdown);

  mkcl_initialize_disable_fpe (env);

  const char *p;
  if (!(p = g_getenv("DISABLECMP")) || !(strcmp(p, "1") == 0)) {
  mkcl_call (env, ("\
(progn\
  (require 'cmp))"));
  }

  mkcl_initialize_crock_debugger (env);
}

void
mkcl_load_and_monitor_initrc ()
{
  g_return_if_fail (stashed_appname);
  /* echo ~/.config/APP${SUFFIX:+.}${SUFFIX}/initrc.lisp */
  const char *override = g_getenv ("INITRC");
  char *initrc = override && *override ? (char *) override : initrc_pathname (stashed_appname);
  load_and_monitor (initrc, loadlispfile, 0);
}

void
mkcl_initialize (char *app)
{
  mkcl_initialize_boot (app);
  mkcl_load_and_monitor_initrc ();
}

mkcl_object
mkcl_init_module (void (*entry_point) (MKCL, mkcl_object, mkcl_object))
{
  g_return_val_if_fail (stashed_env, mk_cl_Cnil);
  return mkcl_read_VV (stashed_env, mk_cl_Cnil, entry_point, mk_cl_Cnil);
}

void
mkcl_initialize_module (char *app,
			void (*entry_point) (MKCL, mkcl_object, mkcl_object))
{
  mkcl_initialize_boot (app);
  mkcl_init_module (entry_point);
  mkcl_load_and_monitor_initrc ();
}

int
mkcl_shutdown ()
{
  g_return_val_if_fail (stashed_env, -1);
  stashed_env->own_thread->thread.status = mkcl_thread_done;
  /* MKCL's shutdown watchdog should be inserted here. */
  return mkcl_shutdown_watchdog (stashed_env);
}

// This code is here to illustrate how the root stack should be setup
// when evaluating lisp from C.  This doesn't actually work because
// MKCL's toplevel wants to run in the main thread, and we want glib's
// loop to run in the main thread.
void
mkcl_repl ()
{
  MKCL = MKCL_ENV();
  MKCL_CATCH_ALL_BEGIN (env)
  {
    MKCL_SETUP_CALL_STACK_ROOT_GUARD (env);
    mkcl_enable_interrupts (env);
    {
      mkcl_object ret = mkcl_call(env, "(SI::TOP-LEVEL)");
      env->own_thread->thread.result_value = ret;
    }
    MKCL_UNSET_CALL_STACK_ROOT_GUARD (env);
  } MKCL_CATCH_ALL_IF_CAUGHT
  {
    MKCL_UNSET_CALL_STACK_ROOT_GUARD (env);
    /* some other late cleanup should go here. */
  } MKCL_CATCH_ALL_END;
}