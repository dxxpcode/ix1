#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

#include "backend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("ix1-shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("ix1"));

    ShellBackend backend;

    const QStringList roots = {
        QStringLiteral("Wallpaper"),
        QStringLiteral("Panel"),
        QStringLiteral("Dock"),
        QStringLiteral("Launcher"),
        QStringLiteral("QuickSettings"),
        QStringLiteral("Calendar"),
        QStringLiteral("Notifications"),
        QStringLiteral("LockScreen"),
    };

    // Engines must outlive the loop: destroying an engine destroys its windows.
    QList<QQmlApplicationEngine *> engines;
    for (const QString &root : roots) {
        auto *engine = new QQmlApplicationEngine(&app);
        engine->rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
        QObject::connect(engine, &QQmlApplicationEngine::objectCreationFailed,
                         &app, [&engine, &root]() {
                             qWarning().noquote() << "ix1-shell: failed to create"
                                                  << root;
                             QCoreApplication::exit(2);
                         }, Qt::QueuedConnection);
        engine->addImportPath(QStringLiteral("qrc:/"));
        engine->loadFromModule(QStringLiteral("Ix1Shell"), root);
        if (engine->rootObjects().isEmpty()) {
            qWarning().noquote() << "ix1-shell: no root objects for" << root;
            return 2;
        }
        engines.append(engine);
    }

    // Headless renders: IX1_SHOT_DIR saves one PNG per root window and
    // exits. IX1_DEMO seeds backend state (wifi/battery/focused app);
    // IX1_SHOW_CAL opens the clock's calendar popover.
    const QString shotDir = qEnvironmentVariable("IX1_SHOT_DIR");
    if (!shotDir.isEmpty()) {
        QTimer::singleShot(1200, &app, [&engines, &roots, shotDir]() {
            QDir().mkpath(shotDir);
            for (int i = 0; i < engines.size(); ++i) {
                for (QObject *o : engines[i]->rootObjects()) {
                    if (auto *w = qobject_cast<QQuickWindow *>(o)) {
                        w->grabWindow().save(shotDir + QLatin1Char('/')
                                             + roots[i].toLower() + QStringLiteral(".png"));
                    }
                }
            }
            QCoreApplication::quit();
        });
    }

    return app.exec();
}
