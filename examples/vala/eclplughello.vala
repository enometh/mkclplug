void main(string[] args) {
    GLib.message("Hello, World\n");
    bool done = false;
    GLib.Unix.signal_add (Posix.Signal.INT, () => {
            done = true;
            return GLib.Source.REMOVE;
        });

    GLib.MainContext ctx = GLib.MainContext.default();
    // ecl doesn't eat up sigint
    EclPlug.ecl_initialize("eclplug-vala-hello");
    EclPlug.ecl_eval("(warn \"18:4 And I heard another voice from heaven, saying, Come out of her, my people, that ye be not partakers of her sins, and that ye receive not of her plagues\")");
    EclPlug.ecl_eval("(warn \"5 For her sins have reached unto heaven, and God hath remembered her iniquities.\")");
    while (!done)
        ctx.iteration(true);
    GLib.message("Goodbye, World\n");
    EclPlug.ecl_shutdown();
}