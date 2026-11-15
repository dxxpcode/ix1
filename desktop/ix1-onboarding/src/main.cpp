#include <QDir>
#include <QFile>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

#include "backend.h"

int main(int argc, char *argv[])
{
    // Runs once per account: a marker in ~/.config ends the intro for
    // good. IX1_FORCE re-shows it; IX1_DEMO seeds render states.
    const QString flagPath =
        QDir::homePath() + QStringLiteral("/.config/ix1/onboarded");
    if (QFile::exists(flagPath) &&
        !qEnvironmentVariableIsSet("IX1_FORCE") &&
        !qEnvironmentVariableIsSet("IX1_DEMO"))
        return 0;

    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("ix1-onboarding"));
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);

    // Bundled Geist faces — loaded from qrc so the live image needs
    // no font packages at all. Only the Medium (500) faces ship: every
    // weight resolves to Medium for one consistent typographic voice.
    for (const char *f : {"geist-500.ttf", "geistmono-500.ttf"})
        QFontDatabase::addApplicationFont(
            QStringLiteral("qrc:/Ix1Onboarding/assets/fonts/%1").arg(QLatin1String(f)));

    Backend backend;
    backend.setFlagPath(flagPath);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    engine.rootContext()->setContextProperty(QStringLiteral("initialStep"),
                                             qEnvironmentVariableIntValue("IX1_STEP"));
    engine.loadFromModule(QStringLiteral("Ix1Onboarding"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty()) {
        qWarning("ix1-onboarding: failed to load Main.qml");
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
