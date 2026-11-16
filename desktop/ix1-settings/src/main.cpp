#include <QGuiApplication>
#include <QDir>
#include <QQuickWindow>
#include <QTimer>
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
    engine.rootContext()->setContextProperty(
        QStringLiteral("demoPage"),
        qEnvironmentVariable("IX1_PAGE").toInt());
    // Headless-render flag: opens the first select's popover.
    engine.rootContext()->setContextProperty(
        QStringLiteral("demoPopup"), qEnvironmentVariableIsSet("IX1_SHOW_POPUP"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(2); }, Qt::QueuedConnection);
    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.loadFromModule(QStringLiteral("Ix1Settings"), QStringLiteral("Main"));

    if (engine.rootObjects().isEmpty()) {
        return 2;
    }

    // Headless renders: IX1_SHOT_DIR saves main.png after the window settles.
    const QString shotDir = qEnvironmentVariable("IX1_SHOT_DIR");
    if (!shotDir.isEmpty()) {
        QTimer::singleShot(1200, &app, [&engine, shotDir]() {
            QDir().mkpath(shotDir);
            for (QObject *o : engine.rootObjects()) {
                if (auto *w = qobject_cast<QQuickWindow *>(o)) {
                    w->grabWindow().save(shotDir + QStringLiteral("/main.png"));
                }
            }
            QCoreApplication::quit();
        });
    }
    return app.exec();
}
