#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

#include "backend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("ix1-installer"));
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);

    // Bundled Geist faces — loaded from qrc so the live image needs
    // no font packages at all.
    for (const char *f : {"geist-400.ttf", "geist-500.ttf", "geist-600.ttf",
                          "geist-700.ttf", "geistmono-400.ttf", "geistmono-500.ttf"})
        QFontDatabase::addApplicationFont(
            QStringLiteral("qrc:/Ix1Installer/assets/fonts/%1").arg(QLatin1String(f)));

    Backend backend;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    engine.rootContext()->setContextProperty(QStringLiteral("initialStep"),
                                             qEnvironmentVariableIntValue("IX1_STEP"));
    engine.loadFromModule(QStringLiteral("Ix1Installer"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty()) {
        qWarning("ix1-installer: failed to load Main.qml");
        return 1;
    }

    // Headless render check: IX1_SCREENSHOT=out.png grabs the window
    // after it settles (used by CI/QEMU verification with -platform offscreen).
    // IX1_SIZE=WxH renders at that size instead of the fullscreen default.
    const QString shot = qEnvironmentVariable("IX1_SCREENSHOT");
    if (!shot.isEmpty()) {
        const QString size = qEnvironmentVariable("IX1_SIZE", QStringLiteral("1600x1000"));
        const QStringList wh = size.split(QLatin1Char('x'));
        for (QWindow *w : QGuiApplication::allWindows())
            if (auto *qw = qobject_cast<QQuickWindow *>(w)) {
                qw->setVisibility(QWindow::Windowed);
                if (wh.size() == 2)
                    qw->resize(wh[0].toInt(), wh[1].toInt());
            }
        QTimer::singleShot(1500, [&app, shot]() {
            for (QWindow *w : QGuiApplication::allWindows())
                if (auto *qw = qobject_cast<QQuickWindow *>(w))
                    qw->grabWindow().save(shot);
            app.quit();
        });
    }
    return app.exec();
}
