#include <ecl/ecl.h>
extern void ecl_initialize (char *app);
extern int ecl_shutdown ();	/* for use in atexit */
extern void ecl_eval (char *fmt, ...);
extern void ecl_initialize_module (char *app, void (*entry) (cl_object));
