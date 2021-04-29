#include <mkcl/mkcl.h>
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
  mkcl_call (env, ("\
(progn\
  (si::disable-fpe 'floating-point-underflow)\
  (si::disable-fpe 'floating-point-overflow))"));
}

static void
mkcl_initialize_write_lisp_backtrace (MKCL)
{
  static int initialized = 0;
  if (!initialized)
    {
      initialized = 1;
      mkcl_call (env, ("\
(defun write-lisp-backtrace (condition)\
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
 (defvar *original-debugger-hook* *debugger-hook*)\
 (defvar *eval-successful-p* t)\
 (defun safe-eval-debugger-hook (condition old-hook)\
   (declare (ignore old-hook))\
   (format t \"Entering safe-eval-debugger-hook~&\")\
   #+nil(si::tpl-backtrace)\
   (write-lisp-backtrace condition)\
   (setq *eval-successful-p* nil)\
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
 (setq *eval-successful-p* t)\
 (setq *debugger-hook* 'safe-eval-debugger-hook))");
  form = mkcl_fast_read_from_cstring (env, p);
  MKCL_CL_CATCH_END;
  mkcl_call (env, "(setq *debugger-hook* *original-debugger-hook*)");
  if (mkcl_fast_read_from_cstring (env, "*EVAL-SUCCESSFUL-P*") == mk_cl_Cnil)
    {
      g_warning ("eval: read failed");
      return;
    }
  MKCL_CL_CATCH_BEGIN (env, tag);
  mkcl_call (env, "\
(progn\
 (setq *eval-successful-p* t)\
 (setq *debugger-hook* 'safe-eval-debugger-hook))");
  ret = mk_cl_eval (env, form);
  MKCL_CL_CATCH_END;
  mkcl_call (env, "(setq *debugger-hook* *original-debugger-hook*)");
  if (mkcl_fast_read_from_cstring (env, "*EVAL-SUCCESSFUL-P*") == mk_cl_Cnil)
    {
      g_warning ("eval: eval failed");
      return;
    }
}


// vararg safe eval
void
mkcl_eval (MKCL, const char *fmt, ...)
{
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

static mkcl_env stashed_env;

static void
loadlispfile (char *lispinitfile)
{
  g_assert (stashed_env);
  MKCL = stashed_env ; //MKCL_ENV();
  gint64 start1, stop1;
  g_debug ("loading %s\n", lispinitfile);
  start1 = g_get_monotonic_time ();
  mkcl_eval (env, "(let ((f \"%s\")) (and (probe-file f) (load f)))",
	     lispinitfile);
  stop1 = g_get_monotonic_time ();
  g_debug ("%s in %g seconds"
	   "= %" G_GINT64_FORMAT " - %" G_GINT64_FORMAT "\n",
	   lispinitfile, (stop1 - start1) / 1.0e6, stop1, start1);
}

void
mkcl_initialize (char *app)
{
  if (stashed_env)
    {
      g_error ("mkcl_initialize: ealready");
      return;
    }

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
  mkcl_initialize_crock_debugger (env);

  /* echo ~/.config/APP${SUFFIX:+.}${SUFFIX}/initrc.lisp */
  char *initrc = initrc_pathname (app);
  load_and_monitor (initrc, loadlispfile, 0);
  g_free (initrc);
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