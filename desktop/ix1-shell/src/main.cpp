#include <QDir>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QMetaProperty>
#include <QPainterPath>
#include <QQuickWindow>
#include <QRegion>
#include <QTimer>

#include <KWindowEffects>

#include <functional>

#include "backend.h"

namespace {

// Runs `apply` now and again (coalesced) whenever `o.prop` notifies.
void watchProperty(QObject *o, QQuickWindow *w, const char *prop, std::function<void()> apply)
{
    const int idx = o->metaObject()->indexOfProperty(prop);
    if (idx < 0) {
        return;
    }
    auto *t = new QTimer(w);
    t->setSingleShot(true);
    QObject::connect(t, &QTimer::timeout, w, std::move(apply));
    QObject::connect(o, o->metaObject()->property(idx).notifySignal(), t,
                     t->metaObject()->method(t->metaObject()->indexOfSlot("start()")));
    t->start();
}

} // namespace

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
        // "tip" or "menu": shows the dock's hover tooltip / pin menu.
        engine->rootContext()->setContextProperty(
            QStringLiteral("demoDock"), qEnvironmentVariable("IX1_SHOW_DOCK"));
        // "q:<text>,cat:<group>,sel:<n>": launcher search/category/highlight.
        engine->rootContext()->setContextProperty(
            QStringLiteral("demoLaunch"), qEnvironmentVariable("IX1_LAUNCH_DEMO"));
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

        // Root windows may declare `inputRect` (where they take input;
        // everything else passes through) and `blurRect`/`blurRadius` (the
        // rounded area KWin blurs behind). Neither exists offscreen.
        if (QGuiApplication::platformName() != QLatin1String("offscreen")) {
            for (QObject *o : engine->rootObjects()) {
                auto *w = qobject_cast<QQuickWindow *>(o);
                if (!w) {
                    continue;
                }
                watchProperty(o, w, "inputRect", [w, o]() {
                    w->setMask(QRegion(o->property("inputRect").toRectF().toAlignedRect()));
                });
                watchProperty(o, w, "blurRect", [w, o]() {
                    const QRectF r = o->property("blurRect").toRectF();
                    const qreal radius = o->property("blurRadius").toReal();
                    QPainterPath path;
                    path.addRoundedRect(r, radius, radius);
                    KWindowEffects::enableBlurBehind(
                        w, true, QRegion(path.toFillPolygon().toPolygon()));
                });
            }
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
