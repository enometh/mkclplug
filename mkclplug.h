#include <mkcl/mkcl.h>
extern void mkcl_initialize (char *app);
extern int mkcl_shutdown ();
extern void mkcl_eval (char *fmt, ...);
extern void mkcl_initialize_module (char *app,
				    void (*entry_point) (MKCL, mkcl_object,
							 mkcl_object));
extern void mkcl_eval_single (char *code);
