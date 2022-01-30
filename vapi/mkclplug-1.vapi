[CCode (cheader_filename = "mkclplug.h")]
namespace MkclPlug {
    [CCode (cname = "mkcl_initialize")]
    void mkcl_initialize (string app);
    [CCode (cname = "mkcl_shutdown")]
    int mkcl_shutdown ();
    [CCode (cname = "mkcl_eval")]
    void mkcl_eval (string fmt, ...);
    [CCode (cname = "entry_point", has_target = false)]
    delegate void entry_point(void *mkcl_env, void *block, void *filename);
    [CCode (cname = "mkcl_initialize_module")]
    void mkcl_initialize_module (string app, entry_point func);
}
