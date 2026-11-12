#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

// Settings backend: appearance (persisted to ~/.config/ix1/settings.conf,
// shared with ix1-shell), sound via WirePlumber (wpctl), network via
// NetworkManager (nmcli). All operations map to the real system services.
class SettingsBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled NOTIFY wifiEnabledChanged)
    Q_PROPERTY(QStringList wifiNetworks READ wifiNetworks NOTIFY wifiNetworksChanged)
    Q_PROPERTY(QString wifiSsid READ wifiSsid NOTIFY wifiSsidChanged)
    Q_PROPERTY(QString hostName READ hostName CONSTANT)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)

public:
    explicit SettingsBackend(QObject *parent = nullptr);

    QString theme() const { return m_theme; }
    void setTheme(const QString &theme);

    int volume() const { return m_volume; }
    void setVolume(int percent);

    bool wifiEnabled() const { return m_wifiEnabled; }
    void setWifiEnabled(bool enabled);

    QStringList wifiNetworks() const { return m_wifiNetworks; }
    QString wifiSsid() const { return m_wifiSsid; }

    QString hostName() const { return m_hostName; }
    QString kernelVersion() const { return m_kernelVersion; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void connectWifi(const QString &ssid, const QString &password);
    Q_INVOKABLE void forgetWifi(const QString &ssid);

signals:
    void themeChanged();
    void volumeChanged();
    void wifiEnabledChanged();
    void wifiNetworksChanged();
    void wifiSsidChanged();

private:
    static QString configDir();
    void loadConfig();
    void saveConfig() const;
    void refreshVolume();
    void refreshWifi();

    QString m_theme = QStringLiteral("graphite");
    int m_volume = -1;
    bool m_wifiEnabled = true;
    QStringList m_wifiNetworks;
    QString m_wifiSsid;
    QString m_hostName;
    QString m_kernelVersion;
};
