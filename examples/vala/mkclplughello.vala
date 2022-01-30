void main(string[] args) {
    GLib.message("Hello, World\n");
    bool done = false;
    MkclPlug.mkcl_initialize("mkclplug-vala-hello");
    GLib.MainContext ctx = GLib.MainContext.default();
    // eat up mkcl's sigint handler!
    GLib.Unix.signal_add (Posix.Signal.INT, () => {
            done = true;
            return GLib.Source.REMOVE;
        });
    MkclPlug.mkcl_eval("(warn \"18:4 And I heard another voice from heaven, saying, Come out of her, my people, that ye be not partakers of her sins, and that ye receive not of her plagues\")");
    MkclPlug.mkcl_eval("(warn \"5 For her sins have reached unto heaven, and God hath remembered her iniquities.\")");
    while (!done)
        ctx.iteration(true);
    GLib.message("Goodbye, World\n");
    MkclPlug.mkcl_shutdown();
}