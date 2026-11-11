#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

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
        QStringLiteral("Notifications"),
        QStringLiteral("LockScreen"),
    };

    for (const QString &root : roots) {
        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
        QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                         &app, []() { QCoreApplication::exit(2); }, Qt::QueuedConnection);
        engine.loadFromModule(QStringLiteral("Ix1Shell"), root);
        if (engine.rootObjects().isEmpty()) {
            return 2;
        }
    }

    return app.exec();
}
