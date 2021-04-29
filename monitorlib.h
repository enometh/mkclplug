typedef void (*watchedcb_t) (char *path);
extern void load_and_monitor (char *lispfilepath, watchedcb_t watchedcb,
			      gboolean unwatch);
