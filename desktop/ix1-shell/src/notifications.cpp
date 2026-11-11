#include "notifications.h"

#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>

namespace {
uint g_nextId = 1;
}

NotificationServer::NotificationServer(QObject *parent)
    : QObject(parent)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerService(QStringLiteral("org.freedesktop.Notifications"))) {
        qWarning("ix1-shell: could not own org.freedesktop.Notifications: %s",
                 qPrintable(bus.lastError().message()));
        return;
    }
    if (!bus.registerObject(QStringLiteral("/org/freedesktop/Notifications"), this,
                            QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals)) {
        qWarning("ix1-shell: could not register notification object: %s",
                 qPrintable(bus.lastError().message()));
    }
}

uint NotificationServer::Notify(const QString &appName, uint replacesId, const QString &appIcon,
                                const QString &summary, const QString &body,
                                const QVariantList &actions, const QVariantMap &hints,
                                int expireTimeout)
{
    Q_UNUSED(appIcon)
    Q_UNUSED(actions)
    Q_UNUSED(hints)

    uint id = g_nextId++;
    if (replacesId != 0) {
        emit notificationClosed(replacesId, 3);
        id = replacesId;
    }
    int timeout = expireTimeout;
    if (timeout < 0) {
        timeout = 5000;
    }
    emit notificationAdded(appName, summary, body, id, timeout);
    return id;
}

void NotificationServer::CloseNotification(uint id)
{
    emit notificationClosed(id, 2);
}

QStringList NotificationServer::GetCapabilities()
{
    return { QStringLiteral("body"), QStringLiteral("body-markup") };
}

QVariantMap NotificationServer::GetServerInformation()
{
    return {
        { QStringLiteral("name"), QStringLiteral("ix1-shell") },
        { QStringLiteral("vendor"), QStringLiteral("ix1") },
        { QStringLiteral("version"), QStringLiteral("0.1") },
        { QStringLiteral("spec_version"), QStringLiteral("1.2") },
    };
}
