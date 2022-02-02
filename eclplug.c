#include <ecl/ecl.h>		/* include before glib. redefines TRUE */
#include <glib.h>
#include "monitorlib.h"

static void
ecl_initialize_disable_fpe ()
{
  const char *p;
  if (!(p = g_getenv ("NODISABLEFPE")) || !(strcmp (p, "1") == 0))
    {
      cl_eval (ecl_read_from_cstring ("(si::trap-fpe t nil)"));
    }
}

static void
ecl_initialize_write_lisp_backtrace (cl_object condition)
{
  static int initialized = 0;
  if (!initialized)
    {
      initialized = 1;
      cl_eval (ecl_read_from_cstring ("\
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

void				//cl_object
ecl_eval (const char *fmt, ...)
{
  char buf[74], *p = buf, *np;
  int n, size = sizeof (buf);;
  va_list ap;

  static cl_object write_lisp_backtrace_sym = NULL;
  if (!write_lisp_backtrace_sym)
    write_lisp_backtrace_sym =
      ecl_make_symbol ("WRITE-LISP-BACKTRACE", "CL-USER");
  while (1)
    {
      va_start (ap, fmt);
      n = vsnprintf (p, size, fmt, ap);
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
	      fprintf (stderr, "eval: couldn't allocate memory: %s\n",
		       strerror (errno));
	      free (p);
	      return		// ECL_NIL; // XXX
		;
	    }
	  else
	    p = np;
	}
    }
//      fprintf(stderr,"str=<<%s>> len=%d\n", p, size);

  cl_env_ptr the_env = ecl_process_env ();
  cl_object form, result;
  int errorp = 0;

  cl_object eval_safe = ecl_make_symbol ("*EVAL-SAFE*", "CL-USER");
  if (ecl_boundp (the_env, eval_safe) &&
      ecl_symbol_value (eval_safe) != ECL_NIL)
    {
      /* Note how the first value to ECL_HANDLER_CASE
         matches the position of the condition name in the
         list: */
      cl_object error = ecl_make_symbol ("ERROR", "CL");
      cl_object my_string = make_base_string_copy (p);
      ECL_HANDLER_CASE_BEGIN (the_env, ecl_list1 (error))
      {
	/* This form is evaluated with bound handlers */
	//;madhu 181120: not ecl_read_from_cstring
	form = cl_read_from_string (1, my_string);
	result = cl_eval (form);
      }
      ECL_HANDLER_CASE (1, condition)
      {
	/* This code is executed when an error happens */
	fprintf (stderr, "-- handling condition ");
	ecl_prin1 (condition, cl_core.error_output);
	fprintf (stderr, " --\n");
	cl_funcall (2, write_lisp_backtrace_sym, condition);
	si_dump_c_backtrace (ecl_make_fixnum (128));
	fprintf (stderr, "-- done --\n");
	errorp = 1;
	result = ECL_NIL;
      }
      ECL_HANDLER_CASE_END;
    }
  else
    {
      cl_object cont = ecl_make_symbol ("CONTINUE", "CL");
      cl_object abrt = ecl_make_symbol ("ABORT", "CL");

      ECL_RESTART_CASE_BEGIN (the_env, cl_list (2, cont, abrt))
      {
	form = ecl_read_from_cstring (p);
	result = cl_eval (form);
      }
      ECL_RESTART_CASE (1, args)
      {
	result = Cnil;
	fprintf (stderr, "continue\n");
	errorp = 1;
      }
      ECL_RESTART_CASE (2, args)
      {
	result = Cnil;
	fprintf (stderr, "abort\n");
	errorp = 1;
      }
      ECL_RESTART_CASE_END;
    }

//      fprintf(stderr, "successp=%d ret=<<", errorp);
//      cl_print(1, result);
//      fprintf(stderr, ">>\n");

  if (!(p == buf))
    free (p);
  // return (errorp ? -1 : 0);
//      return result;
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
  gint64 start1, stop1;
  g_debug ("loading %s\n", lispinitfile);
  start1 = g_get_monotonic_time ();
  ecl_eval ("(let ((f \"%s\")) (and (probe-file f) (load f)))", lispinitfile);
  stop1 = g_get_monotonic_time ();
  g_debug ("%s in %g seconds"
	   "= %" G_GINT64_FORMAT " - %" G_GINT64_FORMAT "\n",
	   lispinitfile, (stop1 - start1) / 1.0e6, stop1, start1);
}

char *stashed_appname;
static int stashed_env;		/* actually boolean initialized */

static void
ecl_initialize_boot (char *app)
{

  if (stashed_env)
    {
      g_error ("ecl_initialize: ealready");
      return;
    }

  g_message ("initializing app %s", app);
  stashed_appname = strdup (app);

  char *argv[] = { app, 0 };
  stashed_env = cl_boot (1, argv);
  // atexit(cl_shutdown);

  ecl_initialize_disable_fpe ();

  const char *p;
  if (!(p = g_getenv ("DISABLECMP")) || !(strcmp (p, "1") == 0))
    {
      cl_eval (ecl_read_from_cstring ("\
(progn\
  (require 'cmp))"));
    }

}

void
ecl_load_and_monitor_initrc ()
{
  g_return_if_fail (stashed_appname);
  /* echo ~/.config/APP${SUFFIX:+.}${SUFFIX}/initrc.lisp */

  const char *override = g_getenv ("INITRC");
  char *initrc = override && *override ? (char *) override : initrc_pathname (stashed_appname);
  load_and_monitor (initrc, loadlispfile, 0);
  if (!override) g_free (initrc);
}

void
ecl_initialize (char *app)
{
  ecl_initialize_boot (app);
  ecl_load_and_monitor_initrc ();
}

int
ecl_shutdown ()
{
  g_return_val_if_fail (stashed_env, -1);
  cl_shutdown ();
  return 1;
}
