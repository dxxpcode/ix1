#include <QDir>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QMetaProperty>
#include <QQuickWindow>
#include <QRegion>
#include <QTimer>

#include "backend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("ix1-shell"));
    QGuiApplication::setOrganizationName(QStringLiteral("ix1"));

    // Bundled Geist faces, loaded from qrc so the image needs no font
    // packages. Only the Medium (500) faces ship — same as the installer
    // and website: one typographic voice across the product.
    for (const char *f : {"geist-500.ttf", "geistmono-500.ttf"}) {
        QFontDatabase::addApplicationFont(
            QStringLiteral("qrc:/Ix1Shell/qml/assets/%1").arg(QLatin1String(f)));
    }

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
        // Headless-render flag: opens the panel's inline volume pill.
        engine->rootContext()->setContextProperty(
            QStringLiteral("demoVol"), qEnvironmentVariableIsSet("IX1_SHOW_VOL"));
        engine->rootContext()->setContextProperty(
            QStringLiteral("demoNet"), qEnvironmentVariableIsSet("IX1_SHOW_NET"));
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

        // A root window may declare `inputRect` to limit where it takes
        // input; everything outside it passes through to what is below.
        for (QObject *o : engine->rootObjects()) {
            auto *w = qobject_cast<QQuickWindow *>(o);
            const int idx = o->metaObject()->indexOfProperty("inputRect");
            if (!w || idx < 0 || QGuiApplication::platformName() == QLatin1String("offscreen")) {
                continue;
            }
            auto *apply = new QTimer(w);
            apply->setSingleShot(true);
            QObject::connect(apply, &QTimer::timeout, w, [w, o]() {
                w->setMask(QRegion(o->property("inputRect").toRectF().toAlignedRect()));
            });
            QObject::connect(o, o->metaObject()->property(idx).notifySignal(), apply,
                             apply->metaObject()->method(
                                 apply->metaObject()->indexOfSlot("start()")));
            apply->start();
        }
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
