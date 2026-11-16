#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QObject>
#include <QStringList>
#include <QVariantList>

class NotificationServer;
class QTimer;

class AppModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        ExecRole,
        DesktopFileRole,
        CategoriesRole,
        GroupRole,
    };

    explicit AppModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const { return static_cast<int>(m_entries.size()); }

    void reload();

signals:
    void countChanged();

private:
    struct Entry {
        QString name;
        QString exec;
        QString desktopFile;
        QString categories;
        QString group;
    };
    QList<Entry> m_entries;
};

class ShellBackend : public QObject
{
    Q_OBJECT
    // The KWin focus script calls methods on this interface name.
    Q_CLASSINFO("D-Bus Interface", "org.ix1.Shell")
    Q_PROPERTY(AppModel *apps READ apps CONSTANT)
    // Launcher data: every app as { name, desktopFile, group }, sorted by
    // name, and the last launched apps (most recent first).
    Q_PROPERTY(QVariantList launcherApps READ launcherApps NOTIFY launcherAppsChanged)
    Q_PROPERTY(QVariantList recentApps READ recentApps NOTIFY recentAppsChanged)
    Q_PROPERTY(QString userName READ userName CONSTANT)
    Q_PROPERTY(QString theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled NOTIFY wifiEnabledChanged)
    Q_PROPERTY(int wifiSignal READ wifiSignal NOTIFY wifiSignalChanged)
    Q_PROPERTY(QString wifiSsid READ wifiSsid NOTIFY wifiSsidChanged)
    Q_PROPERTY(QVariantList wifiNetworks READ wifiNetworks NOTIFY wifiNetworksChanged)
    Q_PROPERTY(int batteryPct READ batteryPct NOTIFY batteryPctChanged)
    Q_PROPERTY(int brightness READ brightness NOTIFY brightnessChanged)
    Q_PROPERTY(bool dnd READ dnd NOTIFY dndChanged)
    Q_PROPERTY(bool bluetoothEnabled READ bluetoothEnabled NOTIFY bluetoothEnabledChanged)
    Q_PROPERTY(QVariantList outputDevices READ outputDevices NOTIFY outputDevicesChanged)
    Q_PROPERTY(QString activeApp READ activeApp NOTIFY activeAppChanged)
    Q_PROPERTY(QStringList runningApps READ runningApps NOTIFY runningAppsChanged)
    // Dock contents: pinned apps in order, then open apps that aren't
    // pinned. Each entry: name, desktopFile, appId, pinned.
    Q_PROPERTY(QVariantList dockApps READ dockApps NOTIFY dockAppsChanged)
    Q_PROPERTY(bool launcherOpen READ launcherOpen NOTIFY launcherOpenChanged)
    Q_PROPERTY(bool quickSettingsOpen READ quickSettingsOpen NOTIFY quickSettingsOpenChanged)
    Q_PROPERTY(QString qsSection READ qsSection NOTIFY qsSectionChanged)
    Q_PROPERTY(bool calendarOpen READ calendarOpen NOTIFY calendarOpenChanged)
    Q_PROPERTY(bool locked READ locked NOTIFY lockedChanged)
    // Empty = theme default; otherwise an absolute path under
    // /usr/share/ix1/wallpapers or the user's data dir.
    Q_PROPERTY(QString wallpaper READ wallpaper NOTIFY wallpaperChanged)

public:
    explicit ShellBackend(QObject *parent = nullptr);

    AppModel *apps() { return &m_apps; }
    QString userName() const { return m_userName; }
    QString theme() const { return m_theme; }
    int volume() const { return m_volume; }
    bool wifiEnabled() const { return m_wifiEnabled; }
    int wifiSignal() const { return m_wifiSignal; }
    QString wifiSsid() const { return m_wifiSsid; }
    QVariantList wifiNetworks() const { return m_wifiNetworks; }
    int batteryPct() const { return m_batteryPct; }
    int brightness() const { return m_brightness; }
    bool dnd() const { return m_dnd; }
    bool bluetoothEnabled() const { return m_bluetoothEnabled; }
    QVariantList outputDevices() const { return m_outputDevices; }
    QString activeApp() const { return m_activeApp; }
    QStringList runningApps() const { return m_runningApps; }
    QVariantList dockApps() const { return m_dockApps; }
    bool launcherOpen() const { return m_launcherOpen; }
    bool quickSettingsOpen() const { return m_qsOpen; }
    QString qsSection() const { return m_qsSection; }
    bool calendarOpen() const { return m_calOpen; }
    bool locked() const { return m_locked; }
    QString wallpaper() const { return m_wallpaper; }
    QVariantList launcherApps() const;
    QVariantList recentApps() const;

    Q_INVOKABLE void launchApp(const QString &desktopFile);
    Q_INVOKABLE bool launchExec(const QString &exec);
    Q_INVOKABLE void setPinned(const QString &appId, bool pinned);
    Q_INVOKABLE void setVolume(int percent);
    Q_INVOKABLE void toggleWifi();
    Q_INVOKABLE void connectWifi(const QString &ssid, const QString &password = QString());
    Q_INVOKABLE void toggleTheme();
    Q_INVOKABLE void setDnd(bool on);
    Q_INVOKABLE void toggleBluetooth();
    Q_INVOKABLE void setOutputDevice(int id);
    Q_INVOKABLE void setBrightness(int percent);
    Q_INVOKABLE void powerAction(const QString &action);
    Q_INVOKABLE void sendTestNotification();
    Q_INVOKABLE void dismissNotification(uint id);
    Q_INVOKABLE void toggleLauncher();
    Q_INVOKABLE void closeLauncher() { setLauncherOpen(false); }
    Q_INVOKABLE void toggleQuickSettings();
    Q_INVOKABLE void openQuickSettings(const QString &section = QString());
    Q_INVOKABLE void closeQuickSettings() { setQuickSettingsOpen(false); }
    Q_INVOKABLE void toggleCalendar();
    Q_INVOKABLE void closeCalendar() { setCalendarOpen(false); }
    Q_INVOKABLE bool verifyPassword(const QString &password);
    Q_INVOKABLE void lock();
    Q_INVOKABLE void unlock(const QString &password);

public slots:
    // Called over the session bus by the KWin focus script.
    void setActiveWindow(const QString &appId);
    void setRunningApps(const QString &joined);

signals:
    void themeChanged();
    void volumeChanged();
    void wifiEnabledChanged();
    void wifiSignalChanged();
    void wifiSsidChanged();
    void wifiNetworksChanged();
    void batteryPctChanged();
    void wallpaperChanged();
    void brightnessChanged();
    void dndChanged();
    void bluetoothEnabledChanged();
    void outputDevicesChanged();
    void activeAppChanged();
    void runningAppsChanged();
    void dockAppsChanged();
    void launcherAppsChanged();
    void recentAppsChanged();
    void launcherOpenChanged();
    void quickSettingsOpenChanged();
    void qsSectionChanged();
    void calendarOpenChanged();
    void lockedChanged();
    void notificationAdded(const QString &appName, const QString &summary,
                           const QString &body, uint id);
    void notificationClosed(uint id);

private slots:
    void onPrepareForSleep(bool goingDown);

private:
    void setLauncherOpen(bool open);
    void setQuickSettingsOpen(bool open);
    void setCalendarOpen(bool open);
    void setLocked(bool locked);
    void refreshVolume();
    void refreshWifi();
    void refreshBattery();
    void refreshBrightness();
    void refreshBluetooth();
    void refreshOutputDevices();
    QString appNameForId(const QString &appId) const;
    QStringList parseDesktopExec(const QString &exec, const QString &name) const;
    void loadTheme();
    void writeSettings();
    void rebuildDock();
    void armIdleTimeouts();
    void noteLaunched(const QString &desktopFile);
    static QString recentsPath();

    AppModel m_apps;
    NotificationServer *m_notifications = nullptr;
    QString m_userName;
    QString m_theme = QStringLiteral("graphite");
    QFileSystemWatcher m_configWatcher;
    int m_volume = -1;
    bool m_wifiEnabled = true;
    int m_wifiSignal = -1;
    QString m_wifiSsid;
    QVariantList m_wifiNetworks;
    int m_batteryPct = -1;
    int m_brightness = -1;
    int m_brightnessMax = 0;
    QString m_brightnessDevice;
    bool m_dnd = false;
    bool m_bluetoothEnabled = false;
    bool m_hasBluetooth = false;
    QVariantList m_outputDevices;
    QString m_activeApp;
    QStringList m_runningApps;
    QStringList m_pinned = {
        QStringLiteral("firefox"),
        QStringLiteral("org.kde.dolphin"),
        QStringLiteral("org.kde.kate"),
        QStringLiteral("org.kde.konsole"),
        QStringLiteral("ix1-settings"),
        QStringLiteral("ix1-software-center"),
    };
    QVariantList m_dockApps;
    bool m_launcherOpen = false;
    bool m_qsOpen = false;
    QString m_qsSection;
    bool m_calOpen = false;
    bool m_locked = false;
    int m_idleTimeoutId = -1;
    int m_suspendTimeoutId = -1;
    // idleLock=/idleSuspend= minutes (idleLock=0 locks never, idleSuspend=0
    // suspends never); written by ix1-settings.
    int m_idleLockMin = 5;
    int m_idleSuspendMin = 0;
    QString m_wallpaper;
    QStringList m_recent;
    QTimer *m_pollTimer = nullptr;
};
