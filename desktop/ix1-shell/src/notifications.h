#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Minimal org.freedesktop.Notifications service backed by D-Bus.
class NotificationServer : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")

public:
    explicit NotificationServer(QObject *parent = nullptr);

public slots:
    uint Notify(const QString &appName, uint replacesId, const QString &appIcon,
                const QString &summary, const QString &body,
                const QVariantList &actions, const QVariantMap &hints,
                int expireTimeout);
    void CloseNotification(uint id);
    QStringList GetCapabilities();
    QVariantMap GetServerInformation();

signals:
    void notificationAdded(const QString &appName, const QString &summary,
                           const QString &body, uint id, int expireTimeout);
    void notificationClosed(uint id, uint reason);
};
