#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QObject>
#include <QStringList>

class NotificationServer;

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
    };
    QList<Entry> m_entries;
};

class ShellBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(AppModel *apps READ apps CONSTANT)
    Q_PROPERTY(QString userName READ userName CONSTANT)
    Q_PROPERTY(QString theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled NOTIFY wifiChanged)
    Q_PROPERTY(QString wifiName READ wifiName NOTIFY wifiChanged)
    Q_PROPERTY(bool airplaneEnabled READ airplaneEnabled NOTIFY airplaneChanged)
    Q_PROPERTY(bool bluetoothAvailable READ bluetoothAvailable NOTIFY bluetoothChanged)
    Q_PROPERTY(bool bluetoothEnabled READ bluetoothEnabled NOTIFY bluetoothChanged)
    Q_PROPERTY(bool brightnessAvailable READ brightnessAvailable NOTIFY brightnessChanged)
    Q_PROPERTY(int brightness READ brightness NOTIFY brightnessChanged)
    Q_PROPERTY(bool dndEnabled READ dndEnabled NOTIFY dndChanged)
    Q_PROPERTY(bool launcherOpen READ launcherOpen NOTIFY launcherOpenChanged)
    Q_PROPERTY(bool quickSettingsOpen READ quickSettingsOpen NOTIFY quickSettingsOpenChanged)
    Q_PROPERTY(bool locked READ locked NOTIFY lockedChanged)

public:
    explicit ShellBackend(QObject *parent = nullptr);

    AppModel *apps() { return &m_apps; }
    QString userName() const { return m_userName; }
    QString theme() const { return m_theme; }
    int volume() const { return m_volume; }
    bool wifiEnabled() const { return m_wifiEnabled; }
    QString wifiName() const { return m_wifiName; }
    bool airplaneEnabled() const { return m_airplane; }
    bool bluetoothAvailable() const { return m_btAvailable; }
    bool bluetoothEnabled() const { return m_btEnabled; }
    bool brightnessAvailable() const { return m_brightnessAvailable; }
    int brightness() const { return m_brightness; }
    bool dndEnabled() const { return m_dnd; }
    bool launcherOpen() const { return m_launcherOpen; }
    bool quickSettingsOpen() const { return m_qsOpen; }
    bool locked() const { return m_locked; }

    Q_INVOKABLE void launchApp(const QString &desktopFile);
    Q_INVOKABLE void launchExec(const QString &exec);
    Q_INVOKABLE void setVolume(int percent);
    Q_INVOKABLE void setBrightness(int percent);
    Q_INVOKABLE void toggleWifi();
    Q_INVOKABLE void toggleBluetooth();
    Q_INVOKABLE void toggleAirplane();
    Q_INVOKABLE void toggleDnd() { setDnd(!m_dnd); }
    Q_INVOKABLE void toggleTheme();
    Q_INVOKABLE void powerAction(const QString &action);
    Q_INVOKABLE void sendTestNotification();
    Q_INVOKABLE void dismissNotification(uint id);
    Q_INVOKABLE void toggleLauncher();
    Q_INVOKABLE void closeLauncher() { setLauncherOpen(false); }
    Q_INVOKABLE void toggleQuickSettings();
    Q_INVOKABLE void closeQuickSettings() { setQuickSettingsOpen(false); }
    Q_INVOKABLE bool verifyPassword(const QString &password);
    Q_INVOKABLE void lock();
    Q_INVOKABLE void unlock(const QString &password);

signals:
    void themeChanged();
    void volumeChanged();
    void wifiChanged();
    void airplaneChanged();
    void bluetoothChanged();
    void brightnessChanged();
    void dndChanged();
    void launcherOpenChanged();
    void quickSettingsOpenChanged();
    void lockedChanged();
    void notificationAdded(const QString &appName, const QString &summary,
                           const QString &body, uint id);
    void notificationClosed(uint id);

private slots:
    void onPrepareForSleep(bool goingDown);

private:
    void setLauncherOpen(bool open);
    void setQuickSettingsOpen(bool open);
    void setLocked(bool locked);
    void refreshVolume();
    void refreshWifi();
    void refreshWifiName();
    void refreshBluetooth();
    void refreshBrightness();
    void setDnd(bool on);
    QStringList parseDesktopExec(const QString &exec, const QString &name) const;
    void loadTheme();

    AppModel m_apps;
    NotificationServer *m_notifications = nullptr;
    QString m_userName;
    QString m_theme = QStringLiteral("graphite");
    QFileSystemWatcher m_configWatcher;
    int m_volume = -1;
    bool m_wifiEnabled = true;
    QString m_wifiName;
    bool m_airplane = false;
    bool m_btAvailable = false;
    bool m_btEnabled = false;
    class QProcess *m_btProbe = nullptr;
    class QProcess *m_wifiProbe = nullptr;
    class QProcess *m_ssidProbe = nullptr;
    bool m_brightnessAvailable = false;
    int m_brightness = -1;
    QString m_backlightDevice;
    int m_backlightMax = 0;
    bool m_dnd = false;
    bool m_launcherOpen = false;
    bool m_qsOpen = false;
    bool m_locked = false;
    int m_idleTimeoutId = -1;
};
