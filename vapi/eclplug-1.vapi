[CCode (cheader_filename = "eclplug.h")]
namespace EclPlug {
    [CCode (cname = "ecl_initialize")]
    void ecl_initialize (string appname);
    [CCode (cname = "ecl_shutdown")]
    int ecl_shutdown ();
    [CCode (cname = "ecl_eval")]
    void ecl_eval (string fmt, ...);
}
