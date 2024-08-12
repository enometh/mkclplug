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
   "ecl", "mkcl", or "none".  The second parameter can also be "ecl",
   "mkcl", or "none", and this can be used to override the value in
   the environment variable, if needed.  Remember this function can be
   called at most once in your program, of course.
*/
#ifndef OMNI_MKCLPLUG_H
#define OMNI_MKCLPLUG_H
static void
initmkclplug(char *env_var_name, char *override) {
#if defined(OMNI_ECL) || defined(OMNI_MKCL)
    enum omni_cl_t { omni_cl_none, omni_cl_default, omni_cl_ecl,
      omni_cl_mkcl } omni_cl;
    const char *omni_cl_s = g_getenv(env_var_name == 0 ? "OMNI_CL" : env_var_name);
    if (omni_cl_s == NULL)
      omni_cl = omni_cl_default;
    else if (g_ascii_strcasecmp(omni_cl_s, "none") == 0)
      omni_cl = omni_cl_none;
    else if (g_ascii_strcasecmp(omni_cl_s, "ecl") == 0)
      omni_cl = omni_cl_ecl;
    else if (g_ascii_strcasecmp(omni_cl_s, "mkcl") == 0)
      omni_cl = omni_cl_mkcl;
    else {
      fprintf(stderr, "unknown value for env var OMNI_CL: %s. Wanted one of ecl mkcl or none. Treating as none.\n", omni_cl_s);
      omni_cl = omni_cl_none;
    }
    // start with omni_cl=none and load at runtime with surfcmd
    if (override) {
	    if (g_ascii_strcasecmp(override, "ecl") == 0)
		    omni_cl = omni_cl_ecl;
	    else if (g_ascii_strcasecmp(override, "mkcl") == 0)
		    omni_cl = omni_cl_mkcl;
	    else {
	      fprintf(stderr, "initmkclplugin: override: wanted one of ecl mkcl %s\n",
		      override);
	    }
    }
#if defined(OMNI_ECL)
    extern void ecl_initialize(char *app);
    if (omni_cl == omni_cl_default) omni_cl = omni_cl_ecl;
    if (omni_cl == omni_cl_ecl)
      ecl_initialize("eclplugtest");
#endif
#if defined(OMNI_MKCL)
    extern void mkcl_initialize(char *app);
    if (omni_cl == omni_cl_default) omni_cl = omni_cl_ecl;
    if (omni_cl == omni_cl_mkcl)
      mkcl_initialize("mkclplugtest");
#endif
#endif
}
#endif // OMNI_MKCLPLUG_H