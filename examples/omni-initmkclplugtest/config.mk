CFLAGS += -ggdb
CFLAGS += -I../../

CFLAGS += `pkg-config --cflags gio-2.0`
LIBS += `pkg-config --libs gio-2.0`

LIBS += -Wl,--export-dynamic

ifdef ECLPLUG
	CFLAGS += -DOMNI_ECL `pkg-config --cflags eclplug-1`
	LIBS += `pkg-config --libs eclplug-1`
endif
ifdef MKCLPLUG
	CFLAGS += -DOMNI_MKCL `pkg-config --cflags mkclplug-1`
	LIBS += `pkg-config --libs mkclplug-1`
endif



