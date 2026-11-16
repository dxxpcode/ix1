#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

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
    Q_PROPERTY(QString osRelease READ osRelease CONSTANT)
    Q_PROPERTY(QString osImage READ osImage NOTIFY updatesChanged)
    Q_PROPERTY(bool updateStaged READ updateStaged NOTIFY updatesChanged)
    Q_PROPERTY(bool rollbackAvailable READ rollbackAvailable NOTIFY updatesChanged)
    Q_PROPERTY(QString updateStatus READ updateStatus NOTIFY updateStatusChanged)
    Q_PROPERTY(bool updateBusy READ updateBusy NOTIFY updateBusyChanged)
    Q_PROPERTY(int flatpakUpdateCount READ flatpakUpdateCount NOTIFY flatpakUpdateCountChanged)
    // Wallpaper pick: absolute path, empty = theme default.
    Q_PROPERTY(QString wallpaper READ wallpaper NOTIFY wallpaperChanged)
    // Each entry: name, path.
    Q_PROPERTY(QVariantList wallpapers READ wallpapers NOTIFY wallpapersChanged)
    // Each entry: name, current (mode string), modes (strings), scale.
    Q_PROPERTY(QVariantList displays READ displays NOTIFY displaysChanged)
    Q_PROPERTY(int brightness READ brightness NOTIFY brightnessChanged)
    Q_PROPERTY(int batteryPct READ batteryPct NOTIFY batteryPctChanged)
    // power_supply status: Charging / Discharging / Full / Not charging.
    Q_PROPERTY(QString batteryStatus READ batteryStatus NOTIFY batteryPctChanged)
    // Minutes; 0 = never.
    Q_PROPERTY(int idleLockMinutes READ idleLockMinutes NOTIFY idleLockChanged)
    Q_PROPERTY(int idleSuspendMinutes READ idleSuspendMinutes NOTIFY idleSuspendChanged)

public:
    explicit SettingsBackend(QObject *parent = nullptr);

    QString theme() const { return m_theme; }
    Q_INVOKABLE void setTheme(const QString &theme);

    int volume() const { return m_volume; }
    Q_INVOKABLE void setVolume(int percent);

    bool wifiEnabled() const { return m_wifiEnabled; }
    Q_INVOKABLE void setWifiEnabled(bool enabled);

    QStringList wifiNetworks() const { return m_wifiNetworks; }
    QString wifiSsid() const { return m_wifiSsid; }

    QString hostName() const { return m_hostName; }
    QString kernelVersion() const { return m_kernelVersion; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void connectWifi(const QString &ssid, const QString &password);
    Q_INVOKABLE void forgetWifi(const QString &ssid);

    QString osRelease() const { return m_osRelease; }
    QString osImage() const { return m_osImage; }
    bool updateStaged() const { return m_updateStaged; }
    bool rollbackAvailable() const { return m_rollbackAvailable; }
    QString updateStatus() const { return m_updateStatus; }
    bool updateBusy() const { return m_updateBusy; }
    int flatpakUpdateCount() const { return m_flatpakUpdateCount; }

    Q_INVOKABLE void refreshUpdates();
    Q_INVOKABLE void checkOsUpdate();
    Q_INVOKABLE void stageOsUpdate();
    Q_INVOKABLE void rollbackOs();
    Q_INVOKABLE void rebootSystem();
    Q_INVOKABLE void updateFlatpakApps();
    Q_INVOKABLE void openSoftwareCenter();

    QString wallpaper() const { return m_wallpaper; }
    Q_INVOKABLE void setWallpaper(const QString &path);
    QVariantList wallpapers() const { return m_wallpapers; }
    QVariantList displays() const { return m_displays; }
    int brightness() const { return m_brightness; }
    int batteryPct() const { return m_batteryPct; }
    QString batteryStatus() const { return m_batteryStatus; }
    int idleLockMinutes() const { return m_idleLockMin; }
    int idleSuspendMinutes() const { return m_idleSuspendMin; }
    Q_INVOKABLE void setIdleLockMinutes(int minutes);
    Q_INVOKABLE void setIdleSuspendMinutes(int minutes);
    Q_INVOKABLE void setBrightness(int percent);
    Q_INVOKABLE void setDisplayMode(const QString &name, const QString &mode);
    Q_INVOKABLE void setDisplayScale(const QString &name, double scale);
    Q_INVOKABLE void refreshDisplays();

signals:
    void themeChanged();
    void volumeChanged();
    void wifiEnabledChanged();
    void wifiNetworksChanged();
    void wifiSsidChanged();
    void updatesChanged();
    void updateStatusChanged();
    void updateBusyChanged();
    void flatpakUpdateCountChanged();
    void wallpaperChanged();
    void wallpapersChanged();
    void displaysChanged();
    void brightnessChanged();
    void batteryPctChanged();
    void idleLockChanged();
    void idleSuspendChanged();

private:
    static QString configDir();
    void loadConfig();
    void saveConfig() const;
    void refreshVolume();
    void refreshWifi();
    void refreshWallpapers();
    void refreshPower();
    void setUpdateStatus(const QString &status);
    void setUpdateBusy(bool busy);
    void startUpdateOp(const QStringList &program, int kind);

    QString m_theme = QStringLiteral("graphite");
    int m_volume = -1;
    bool m_wifiEnabled = true;
    QStringList m_wifiNetworks;
    QString m_wifiSsid;
    QString m_hostName;
    QString m_kernelVersion;
    QString m_osRelease = QStringLiteral("dev");
    QString m_osImage;
    bool m_updateStaged = false;
    bool m_rollbackAvailable = false;
    QString m_updateStatus;
    bool m_updateBusy = false;
    int m_flatpakUpdateCount = -1;
    QString m_wallpaper;
    QVariantList m_wallpapers;
    QVariantList m_displays;
    int m_brightness = -1;
    int m_batteryPct = -1;
    QString m_batteryStatus;
    int m_idleLockMin = 5;
    int m_idleSuspendMin = 0;
    class QProcess *m_updateProc = nullptr;
    int m_updateOpKind = 0;
};
