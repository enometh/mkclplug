extern void mkcl_initialize (char *app);
extern int mkcl_shutdown ();
//extern void mkcl_repl ();
extern void mkcl_eval(mkcl_env, char *fmt, ...);
extern mkcl_object mkcl_init_module(void (*entry_point)(MKCL, mkcl_object, mkcl_object));
