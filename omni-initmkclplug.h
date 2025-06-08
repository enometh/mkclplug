//
//   Time-stamp: <>
//   Touched: Mon Aug 12 16:39:18 2024 +0530 <enometh@net.meer>
//   Bugs-To: enometh@net.meer
//   Status: Experimental.  Do not redistribute
//   Copyright (C) 2024 Madhu.  All Rights Reserved.
//

/* a "template" for supporting both mkclplug and eclplug in the same
   program. Of course only one can be used eventually, but this delays
   the choice of lisp as much as possible.  Arrange to have your build
   system define -DOMNI_ECL or -DOMNI_MKCL for the C compiler and
   include this file after including glib headers.  Call
   initmkclplug(0,0) at a suitable point in your program.  The first
   parameter is the name of an environment variable, which defaults to
   "OMNI_CL" if NULL.  The value of this environmnent variable can be
   "ecl", "mkcl", "default", or "none".  The second parameter can also
   be "ecl", "mkcl", "default", or "none", and this can be used to
   override the value in the environment variable, if needed.
   Remember this function can be called at most once in your program,
   of course, if it actually initializes ecl or mkcl.

  If the environment variable is empty or not specified it is assumed
  to be "default", which follows the order of the switch statement in
  the code i.e. to choose ecl if it is compiled in, and if not, mkcl,
  if it is compiled in.

  Operational Modes:

  1.  #include <omni-initmkclplug.h>

	exactly once in one of your C files to include a static
	definition of `initmkclplug' which you can call further down.
	This is the simplest way to use it.

  2a. #define OMNI_MKCLPLUG_DECL
      #include <omni-initmkclplug.h>

	in any C file to make the declaration of `initmkclplug'
	available before you call it.

   2b. #define OMNI_MKCLPLUG_IMPL
       #include <omni-initmkclplug.h>

	exactly once in one of your C files to define the
	implementation of `initmkclplug'

*/
#ifndef OMNI_MKCLPLUG_H
#define OMNI_MKCLPLUG_H

#if defined(OMNI_MKCLPLUG_DECL) || defined(OMNI_MKCLPLUG_IMPL)
#define OMNI_STATIC
#else
#define OMNI_STATIC static
#endif

OMNI_STATIC void initmkclplug(char *env_var_name, char *override);

#if defined(OMNI_MKCLPLUG_IMPL) || (!defined(OMNI_MKCLPLUG_DECL) && !defined(OMNI_MKCLPLUG_IMPL))
OMNI_STATIC void
initmkclplug(char *env_var_name, char *override) {
#if defined(OMNI_ECL)
    extern void ecl_initialize(char *app);
#endif
#if defined(OMNI_MKCL)
    extern void mkcl_initialize(char *app);
#endif

#if defined(OMNI_ECL) || defined(OMNI_MKCL)
    enum omni_cl_t { omni_cl_none, omni_cl_default, omni_cl_ecl,
      omni_cl_mkcl } omni_cl;
    const char *omni_cl_s = g_getenv(env_var_name == 0 ? "OMNI_CL" : env_var_name);
    if (omni_cl_s == NULL || *omni_cl_s == '\0')
      omni_cl = omni_cl_default;
    else if (g_ascii_strcasecmp(omni_cl_s, "default") == 0)
      omni_cl = omni_cl_default;
    else if (g_ascii_strcasecmp(omni_cl_s, "none") == 0)
      omni_cl = omni_cl_none;
    else if (g_ascii_strcasecmp(omni_cl_s, "ecl") == 0)
      omni_cl = omni_cl_ecl;
    else if (g_ascii_strcasecmp(omni_cl_s, "mkcl") == 0)
      omni_cl = omni_cl_mkcl;
    else {
      fprintf(stderr, "unknown value for env var OMNI_CL: %s. Wanted one of ecl, mkcl, default, or none. Treating as none.\n", omni_cl_s);
      omni_cl = omni_cl_none;
    }
    // start with omni_cl=none and load at runtime with surfcmd
    if (override) {
	    if (g_ascii_strcasecmp(override, "ecl") == 0)
		    omni_cl = omni_cl_ecl;
	    else if (g_ascii_strcasecmp(override, "mkcl") == 0)
		    omni_cl = omni_cl_mkcl;
	    else if (g_ascii_strcasecmp(override, "default") == 0)
		    omni_cl = omni_cl_default;
	    else if (g_ascii_strcasecmp(override, "none") == 0)
		    omni_cl = omni_cl_none;
	    else {
	      fprintf(stderr, "initmkclplugin: %s. override: wanted one of ecl, mkcl, default, or none\n",
		      override);
	    }
    }
#if defined(OMNI_ECL)
    if (omni_cl == omni_cl_default) omni_cl = omni_cl_ecl;
    if (omni_cl == omni_cl_ecl)
      ecl_initialize("eclplugtest");
#endif
#if defined(OMNI_MKCL)
    if (omni_cl == omni_cl_default) omni_cl = omni_cl_mkcl;
    if (omni_cl == omni_cl_mkcl)
      mkcl_initialize("mkclplugtest");
#endif
#endif
}
#endif //OMNI_MKCL_PLUG_IMPL

#if defined(OMNI_MKCLPLUG_DECL) || defined(OMNI_MKCLPLUG_IMPL)
#undef OMNI_STATIC
#endif

#endif // OMNI_MKCLPLUG_H
