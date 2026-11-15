// ix1 KWin script: report the focused window's app id and the set of open
// apps to the shell. The focused app shows in the panel's brand area; the
// open set drives the dock's running indicators. Loaded by ix1-session.
function appIdOf(window) {
    return String(window.resourceClass || window.resourceName || "");
}

function report(window) {
    try {
        callDBus("org.ix1.Shell", "/Window", "org.ix1.Shell",
                 "setActiveWindow", window ? appIdOf(window) : "");
    } catch (e) {}
}

function reportWindows() {
    try {
        var list = workspace.windowList ? workspace.windowList()
                                        : workspace.stackingOrder;
        var ids = [];
        for (var i = 0; i < list.length; ++i) {
            var w = list[i];
            if (!w || w.skipTaskbar || w.desktopWindow) {
                continue;
            }
            var id = appIdOf(w);
            if (id && ids.indexOf(id) < 0) {
                ids.push(id);
            }
        }
        callDBus("org.ix1.Shell", "/Window", "org.ix1.Shell",
                 "setRunningApps", ids.join(";"));
    } catch (e) {}
}

workspace.windowActivated.connect(function (w) {
    report(w);
    reportWindows();
});
workspace.windowAdded.connect(reportWindows);
workspace.windowRemoved.connect(reportWindows);
report(workspace.activeWindow);
reportWindows();
