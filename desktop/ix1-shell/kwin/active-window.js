// ix1 KWin script: report the focused window's app id to the shell, which
// shows it in the panel's brand area. Loaded by ix1-session at login.
function report(window) {
    try {
        var appId = "";
        if (window) {
            appId = String(window.resourceClass || window.resourceName || "");
        }
        callDBus("org.ix1.Shell", "/Window", "org.ix1.Shell",
                 "setActiveWindow", appId);
    } catch (e) {}
}
workspace.windowActivated.connect(report);
report(workspace.activeWindow);
