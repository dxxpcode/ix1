#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "backend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("ix1-settings"));
    app.setOrganizationName(QStringLiteral("ix1"));

    SettingsBackend backend;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backend"), &backend);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(2); }, Qt::QueuedConnection);
    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.loadFromModule(QStringLiteral("Ix1Settings"), QStringLiteral("Main"));

    if (engine.rootObjects().isEmpty()) {
        return 2;
    }
    return app.exec();
}
