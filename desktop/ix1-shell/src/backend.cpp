#include "backend.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>
#include <QVariantMap>

#include <KIdleTime>

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <pwd.h>
#include <security/pam_appl.h>
#include <unistd.h>

#include "notifications.h"

namespace {

constexpr int kIdleLockMs = 5 * 60 * 1000;

// nmcli -t separates fields with ':' and escapes a literal ':' as '\\:'.
QStringList splitNmcliRow(const QString &row)
{
    QStringList fields;
    QString cur;
    for (int i = 0; i < row.size(); ++i) {
        const QChar c = row.at(i);
        if (c == QLatin1Char('\\') && i + 1 < row.size()) {
            cur += row.at(++i);
        } else if (c == QLatin1Char(':')) {
            fields << cur;
            cur.clear();
        } else {
            cur += c;
        }
    }
    fields << cur;
    return fields;
}

QStringList desktopEntryPaths()
{
    QStringList dirs = {
        QStringLiteral("/usr/local/share/applications"),
        QStringLiteral("/usr/share/applications"),
        QDir::homePath() + QStringLiteral("/.local/share/applications"),
        // Flatpak application exports (user + system).
        QDir::homePath() + QStringLiteral("/.local/share/flatpak/exports/share/applications"),
        QStringLiteral("/var/lib/flatpak/exports/share/applications"),
    };
    QStringList files;
    for (const QString &dir : dirs) {
        QDir d(dir);
        if (!d.exists()) {
            continue;
        }
        const QStringList names = d.entryList({ QStringLiteral("*.desktop") }, QDir::Files, QDir::Name);
        for (const QString &name : names) {
            files.append(d.absoluteFilePath(name));
        }
    }
    return files;
}

struct DesktopEntry {
    QString name;
    QString exec;
    QString categories;
    bool valid = false;
};

DesktopEntry parseDesktopFile(const QString &path)
{
    DesktopEntry entry;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return entry;
    }
    bool inDesktopEntry = false;
    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.startsWith(QLatin1Char('['))) {
            inDesktopEntry = (line == QLatin1String("[Desktop Entry]"));
            continue;
        }
        if (!inDesktopEntry || line.isEmpty() || line.startsWith(QLatin1Char('#'))) {
            continue;
        }
        const int eq = line.indexOf(QLatin1Char('='));
        if (eq < 0) {
            continue;
        }
        const QString key = line.left(eq).trimmed();
        QString value = line.mid(eq + 1).trimmed();
        if (key == QLatin1String("Type") && value != QLatin1String("Application")) {
            return DesktopEntry{};
        }
        if (key == QLatin1String("NoDisplay") && value == QLatin1String("true")) {
            return DesktopEntry{};
        }
        if (key == QLatin1String("Hidden") && value == QLatin1String("true")) {
            return DesktopEntry{};
        }
        if (key == QLatin1String("Name")) {
            entry.name = value;
        } else if (key == QLatin1String("Exec")) {
            entry.exec = value;
        } else if (key == QLatin1String("Categories")) {
            entry.categories = value;
        }
    }
    entry.valid = !entry.name.isEmpty() && !entry.exec.isEmpty();
    return entry;
}

} // namespace

AppModel::AppModel(QObject *parent)
    : QAbstractListModel(parent)
{
    reload();
}

int AppModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : static_cast<int>(m_entries.size());
}

QVariant AppModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size()) {
        return {};
    }
    const Entry &e = m_entries.at(index.row());
    switch (role) {
    case NameRole: return e.name;
    case ExecRole: return e.exec;
    case DesktopFileRole: return e.desktopFile;
    case CategoriesRole: return e.categories;
    default: return {};
    }
}

QHash<int, QByteArray> AppModel::roleNames() const
{
    return {
        { NameRole, "name" },
        { ExecRole, "exec" },
        { DesktopFileRole, "desktopFile" },
        { CategoriesRole, "categories" },
    };
}

void AppModel::reload()
{
    beginResetModel();
    m_entries.clear();
    const QStringList paths = desktopEntryPaths();
    for (const QString &path : paths) {
        const DesktopEntry e = parseDesktopFile(path);
        if (!e.valid) {
            continue;
        }
        m_entries.append({ e.name, e.exec, path, e.categories });
    }
    std::sort(m_entries.begin(), m_entries.end(), [](const Entry &a, const Entry &b) {
        return a.name.compare(b.name, Qt::CaseInsensitive) < 0;
    });
    endResetModel();
    emit countChanged();
}

ShellBackend::ShellBackend(QObject *parent)
    : QObject(parent)
    , m_notifications(new NotificationServer(this))
{
    loadTheme();
    m_userName = QStandardPaths::displayName(QStandardPaths::HomeLocation).isEmpty()
        ? QStringLiteral("ix1")
        : QStringLiteral("ix1");
    if (const auto pw = getpwuid(getuid())) {
        m_userName = QString::fromLocal8Bit(pw->pw_name);
    }

    connect(m_notifications, &NotificationServer::notificationAdded,
            this, [this](const QString &appName, const QString &summary,
                         const QString &body, uint id) {
                if (!m_dnd) {
                    emit notificationAdded(appName, summary, body, id);
                }
            });
    connect(m_notifications, &NotificationServer::notificationClosed,
            this, &ShellBackend::notificationClosed);

    m_apps.reload();

    // Session-bus endpoint the KWin focus script calls to report the
    // active window's app id (see kwin/active-window.js).
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    sessionBus.registerService(QStringLiteral("org.ix1.Shell"));
    sessionBus.registerObject(QStringLiteral("/Window"), this,
                              QDBusConnection::ExportAllSlots);

    QTimer::singleShot(0, this, [this]() {
        refreshVolume();
        refreshWifi();
        refreshBattery();
        refreshBrightness();
        refreshBluetooth();
        refreshOutputDevices();
    });

    // Signal and battery drift while the desktop sits idle.
    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(15000);
    connect(m_pollTimer, &QTimer::timeout, this, [this]() {
        refreshWifi();
        refreshBattery();
        refreshOutputDevices();
        refreshBluetooth();
    });
    m_pollTimer->start();

    // Headless-render seeding (see IX1_SHOT_DIR in main.cpp).
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        m_wifiEnabled = true;
        m_wifiSignal = 78;
        m_batteryPct = 82;
        m_volume = 45;
        m_brightness = 68;
        m_wifiSsid = QStringLiteral("ix1-home");
        m_wifiNetworks = {
            QVariantMap{ { QStringLiteral("ssid"), QStringLiteral("ix1-home") },
                         { QStringLiteral("signal"), 78 },
                         { QStringLiteral("secure"), true },
                         { QStringLiteral("inUse"), true } },
            QVariantMap{ { QStringLiteral("ssid"), QStringLiteral("coffeehouse-5g") },
                         { QStringLiteral("signal"), 62 },
                         { QStringLiteral("secure"), true },
                         { QStringLiteral("inUse"), false } },
            QVariantMap{ { QStringLiteral("ssid"), QStringLiteral("xfinitywifi") },
                         { QStringLiteral("signal"), 38 },
                         { QStringLiteral("secure"), false },
                         { QStringLiteral("inUse"), false } },
        };
        m_activeApp = QStringLiteral("Firefox");
        m_runningApps = { QStringLiteral("firefox") };
        m_bluetoothEnabled = true;
        m_hasBluetooth = true;
        m_outputDevices = {
            QVariantMap{ { QStringLiteral("id"), 42 },
                         { QStringLiteral("name"), QStringLiteral("Headphones") },
                         { QStringLiteral("active"), true } },
            QVariantMap{ { QStringLiteral("id"), 43 },
                         { QStringLiteral("name"), QStringLiteral("Speakers") },
                         { QStringLiteral("active"), false } },
        };
        if (qEnvironmentVariableIsSet("IX1_SHOW_CAL")) {
            m_calOpen = true;
        }
        if (qEnvironmentVariableIsSet("IX1_SHOW_QS")) {
            m_qsOpen = true;
        }
        if (qEnvironmentVariableIsSet("IX1_SHOW_LAUNCH")) {
            m_launcherOpen = true;
        }
        // A demo toast so headless renders show the notification material.
        // Deferred: the emit must land after the QML engines connect.
        QTimer::singleShot(600, this, [this]() {
            emit notificationAdded(QStringLiteral("ix1"),
                                   QStringLiteral("Welcome to ix1"),
                                   QStringLiteral("Your desktop is up to date."), 1);
        });
    }

    // Idle + suspend locking. KDE's own locker daemon is disabled
    // (/etc/xdg/kscreenlockerrc): its greeter aborts in this image, and
    // ix1's LockScreen is the only lock surface — so idle and suspend
    // locking are the shell's job. KIdleTime talks to KWin's idle
    // protocol; logind announces suspend on the system bus.
    auto *idle = KIdleTime::instance();
    m_idleTimeoutId = idle->addIdleTimeout(kIdleLockMs);
    connect(idle, &KIdleTime::timeoutReached, this,
            [this](int id, int) {
                if (id == m_idleTimeoutId) {
                    setLocked(true);
                }
            });
    QDBusConnection::systemBus().connect(
        QStringLiteral("org.freedesktop.login1"),
        QStringLiteral("/org/freedesktop/login1"),
        QStringLiteral("org.freedesktop.login1.Manager"),
        QStringLiteral("PrepareForSleep"), this,
        SLOT(onPrepareForSleep(bool)));

    // Live theme switching: ix1-settings writes ~/.config/ix1/settings.conf.
    // The file may not exist at startup (QFileSystemWatcher cannot watch a
    // nonexistent file), so watch the config directory as well and re-arm the
    // file watch whenever it appears or is recreated.
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                              + QStringLiteral("/ix1");
    QDir().mkpath(configDir);
    const QString configPath = configDir + QStringLiteral("/settings.conf");
    m_configWatcher.addPath(configDir);
    if (QFileInfo::exists(configPath)) {
        m_configWatcher.addPath(configPath);
    }
    const auto onConfigChanged = [this, configPath]() {
        if (!m_configWatcher.files().contains(configPath) && QFileInfo::exists(configPath)) {
            m_configWatcher.addPath(configPath);
        }
        QTimer::singleShot(100, this, &ShellBackend::loadTheme);
    };
    connect(&m_configWatcher, &QFileSystemWatcher::fileChanged, this, onConfigChanged);
    connect(&m_configWatcher, &QFileSystemWatcher::directoryChanged, this, onConfigChanged);
}

void ShellBackend::loadTheme()
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                         + QStringLiteral("/ix1/settings.conf");
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    QTextStream in(&file);
    while (!in.atEnd()) {
        const QString line = in.readLine().trimmed();
        if (line.startsWith(QLatin1String("dnd="))) {
            const bool on = line.mid(4).trimmed() == QLatin1String("true");
            if (on != m_dnd) {
                m_dnd = on;
                emit dndChanged();
            }
            continue;
        }
        if (!line.startsWith(QLatin1String("theme="))) {
            continue;
        }
        const QString value = line.mid(6).trimmed();
        if ((value == QLatin1String("graphite") || value == QLatin1String("porcelain")) && value != m_theme) {
            m_theme = value;
            emit themeChanged();
        }
    }
}

void ShellBackend::writeSettings()
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                         + QStringLiteral("/ix1/settings.conf");
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        return;
    }
    QTextStream out(&file);
    out << "theme=" << m_theme << '\n';
    out << "dnd=" << (m_dnd ? "true" : "false") << '\n';
}

void ShellBackend::toggleTheme()
{
    m_theme = (m_theme == QLatin1String("graphite"))
        ? QStringLiteral("porcelain") : QStringLiteral("graphite");
    writeSettings();
    emit themeChanged();
}

void ShellBackend::setDnd(bool on)
{
    if (m_dnd == on) {
        return;
    }
    m_dnd = on;
    writeSettings();
    emit dndChanged();
}

QStringList ShellBackend::parseDesktopExec(const QString &exec, const QString &name) const
{
    QString cleaned = exec;
    cleaned.replace(QLatin1String("%c"), name);
    // Drop field codes that take arguments we do not support.
    for (const QString &code : { QStringLiteral("%f"), QStringLiteral("%F"), QStringLiteral("%u"),
                                 QStringLiteral("%U"), QStringLiteral("%d"), QStringLiteral("%D"),
                                 QStringLiteral("%n"), QStringLiteral("%N"), QStringLiteral("%i"),
                                 QStringLiteral("%k"), QStringLiteral("%v"), QStringLiteral("%m") }) {
        cleaned.remove(code);
    }
    cleaned.replace(QLatin1String("%%"), QLatin1String("%"));

    QStringList tokens;
    QString current;
    bool inQuote = false;
    bool escaped = false;
    for (const QChar c : cleaned) {
        if (escaped) {
            current.append(c);
            escaped = false;
            continue;
        }
        if (c == QLatin1Char('\\')) {
            escaped = true;
            continue;
        }
        if (c == QLatin1Char('"')) {
            inQuote = !inQuote;
            continue;
        }
        if (c.isSpace() && !inQuote) {
            if (!current.isEmpty()) {
                tokens.append(current);
                current.clear();
            }
            continue;
        }
        current.append(c);
    }
    if (!current.isEmpty()) {
        tokens.append(current);
    }
    return tokens;
}

void ShellBackend::launchExec(const QString &exec)
{
    const QStringList tokens = parseDesktopExec(exec, QString());
    if (tokens.isEmpty()) {
        return;
    }
    QProcess::startDetached(tokens.constFirst(), tokens.mid(1));
}

void ShellBackend::launchApp(const QString &desktopFile)
{
    for (int i = 0; i < m_apps.rowCount(); ++i) {
        const QModelIndex idx = m_apps.index(i, 0);
        if (m_apps.data(idx, AppModel::DesktopFileRole).toString() == desktopFile) {
            launchExec(m_apps.data(idx, AppModel::ExecRole).toString());
            return;
        }
    }
}

void ShellBackend::refreshVolume()
{
    // IX1_DEMO seeds fixed values for headless renders; real
    // hardware probes would overwrite them.
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    QProcess p;
    p.start(QStringLiteral("wpctl"), { QStringLiteral("get-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@") });
    if (p.waitForFinished(2000)) {
        const QString out = QString::fromLocal8Bit(p.readAllStandardOutput());
        const QString num = out.section(QLatin1Char(':'), -1).trimmed();
        if (num.isEmpty()) {
            return;
        }
        const float v = num.toFloat();
        if (v >= 0.0f) {
            m_volume = qBound(0, qRound(v * 100.0f), 150);
            emit volumeChanged();
        }
    }
}

void ShellBackend::setVolume(int percent)
{
    const int clamped = qBound(0, percent, 150);
    QProcess::startDetached(QStringLiteral("wpctl"),
                            { QStringLiteral("set-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@"),
                              QStringLiteral("%1%").arg(clamped) });
    QTimer::singleShot(150, this, &ShellBackend::refreshVolume);
}

void ShellBackend::refreshWifi()
{
    // IX1_DEMO seeds fixed values for headless renders; real
    // hardware probes would overwrite them.
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    QProcess p;
    p.start(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("WIFI"),
                                        QStringLiteral("radio") });
    if (p.waitForFinished(3000)) {
        const QString out = QString::fromLocal8Bit(p.readAllStandardOutput()).trimmed();
        const bool enabled = (out == QLatin1String("enabled"));
        if (enabled != m_wifiEnabled) {
            m_wifiEnabled = enabled;
            emit wifiEnabledChanged();
        }
    }

    int signal = -1;
    QString ssid;
    QVariantList networks;
    bool got = !m_wifiEnabled;  // disabled radio is a definitive -1
    if (m_wifiEnabled) {
        QProcess s;
        s.start(QStringLiteral("nmcli"),
                { QStringLiteral("-t"), QStringLiteral("-f"),
                  QStringLiteral("IN-USE,SSID,SIGNAL,SECURITY"), QStringLiteral("dev"),
                  QStringLiteral("wifi") });
        if (s.waitForFinished(3000)) {
            got = true;
            const QStringList rows = QString::fromLocal8Bit(s.readAllStandardOutput())
                                         .split(QLatin1Char('\n'), Qt::SkipEmptyParts);
            QMap<QString, QVariantMap> dedup;
            for (const QString &row : rows) {
                // IN-USE,SSID,SIGNAL,SECURITY — AP in use marked "*".
                const QStringList f = splitNmcliRow(row);
                if (f.size() < 4) {
                    continue;
                }
                const bool inUse = f.at(0) == QLatin1Char('*');
                const QString name = f.at(1);
                const int sig = qBound(0, f.at(2).toInt(), 100);
                const bool secure = f.at(3) != QLatin1String("--")
                                    && !f.at(3).isEmpty();
                if (inUse) {
                    signal = sig;
                    ssid = name;
                }
                if (name.isEmpty()) {
                    continue;  // hidden APs carry no SSID field
                }
                QVariantMap entry{
                    { QStringLiteral("ssid"), name },
                    { QStringLiteral("signal"), sig },
                    { QStringLiteral("secure"), secure },
                    { QStringLiteral("inUse"), inUse },
                };
                if (dedup.contains(name)) {
                    const QVariantMap prev = dedup.value(name);
                    if (prev.value(QStringLiteral("signal")).toInt() >= sig) {
                        entry = prev;
                    }
                    entry[QStringLiteral("inUse")] =
                        inUse || prev.value(QStringLiteral("inUse")).toBool();
                }
                dedup.insert(name, entry);
            }
            networks.clear();
            networks.reserve(dedup.size());
            for (const QVariantMap &entry : dedup.values()) {
                networks.append(QVariant(entry));
            }
            std::sort(networks.begin(), networks.end(),
                      [](const QVariant &a, const QVariant &b) {
                          const QVariantMap ma = a.toMap(), mb = b.toMap();
                          if (ma.value(QStringLiteral("inUse")).toBool()
                              != mb.value(QStringLiteral("inUse")).toBool()) {
                              return ma.value(QStringLiteral("inUse")).toBool();
                          }
                          return ma.value(QStringLiteral("signal")).toInt()
                                 > mb.value(QStringLiteral("signal")).toInt();
                      });
        }
    }
    // A failed nmcli call keeps the last reading; a successful one with
    // no active AP reports -1 (wifi on, not connected).
    if (!got) {
        return;
    }
    if (signal != m_wifiSignal) {
        m_wifiSignal = signal;
        emit wifiSignalChanged();
    }
    if (ssid != m_wifiSsid) {
        m_wifiSsid = ssid;
        emit wifiSsidChanged();
    }
    if (networks != m_wifiNetworks) {
        m_wifiNetworks = networks;
        emit wifiNetworksChanged();
    }
}

void ShellBackend::connectWifi(const QString &ssid, const QString &password)
{
    if (ssid.isEmpty() || (ssid == m_wifiSsid && password.isEmpty())) {
        return;
    }
    QStringList args{ QStringLiteral("dev"), QStringLiteral("wifi"),
                      QStringLiteral("connect"), ssid };
    if (!password.isEmpty()) {
        // Saved profiles work without a password; a fresh secured AP needs one.
        args << QStringLiteral("password") << password;
    }
    QProcess::startDetached(QStringLiteral("nmcli"), args);
    QTimer::singleShot(2500, this, &ShellBackend::refreshWifi);
}

void ShellBackend::refreshBrightness()
{
    // IX1_DEMO seeds fixed values for headless renders; real
    // hardware probes would overwrite them.
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    const QDir dir(QStringLiteral("/sys/class/backlight"));
    const QStringList devs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    if (devs.isEmpty()) {
        m_brightnessDevice.clear();
        if (m_brightness != -1) {
            m_brightness = -1;
            emit brightnessChanged();
        }
        return;
    }
    m_brightnessDevice = devs.constFirst();
    QFile bf(dir.filePath(m_brightnessDevice + QStringLiteral("/brightness")));
    QFile mf(dir.filePath(m_brightnessDevice + QStringLiteral("/max_brightness")));
    if (!bf.open(QIODevice::ReadOnly | QIODevice::Text)
        || !mf.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }
    const int max = QString::fromLocal8Bit(mf.readAll()).trimmed().toInt();
    const int cur = QString::fromLocal8Bit(bf.readAll()).trimmed().toInt();
    if (max <= 0) {
        return;
    }
    m_brightnessMax = max;
    const int pct = qBound(0, qRound(cur * 100.0 / max), 100);
    if (pct != m_brightness) {
        m_brightness = pct;
        emit brightnessChanged();
    }
}

void ShellBackend::setBrightness(int percent)
{
    if (m_brightnessDevice.isEmpty()) {
        return;
    }
    const int pct = qBound(1, percent, 100);
    // logind's SetBrightness takes a RAW brightness value, not a percent —
    // scale against the device's max (its owner may set its own backlight).
    const quint32 raw = static_cast<quint32>(qBound(1, qRound(pct * m_brightnessMax / 100.0),
                                                    m_brightnessMax));
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.login1"),
        QStringLiteral("/org/freedesktop/login1/session/auto"),
        QStringLiteral("org.freedesktop.login1.Session"),
        QStringLiteral("SetBrightness"));
    msg << QStringLiteral("backlight") << m_brightnessDevice << raw;
    QDBusConnection::systemBus().asyncCall(msg);
    if (pct != m_brightness) {
        m_brightness = pct;
        emit brightnessChanged();
    }
    QTimer::singleShot(400, this, &ShellBackend::refreshBrightness);
}

void ShellBackend::refreshBattery()
{
    // IX1_DEMO seeds fixed values for headless renders; real
    // hardware probes would overwrite them.
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    const QDir power(QStringLiteral("/sys/class/power_supply"));
    const QStringList bats = power.entryList({ QStringLiteral("BAT*") }, QDir::Dirs | QDir::NoDotAndDotDot);
    if (bats.isEmpty()) {
        return;  // no battery on this machine — keep whatever we have
    }
    int pct = -1;
    for (const QString &bat : bats) {
        QFile cap(power.absoluteFilePath(bat + QStringLiteral("/capacity")));
        if (cap.open(QIODevice::ReadOnly | QIODevice::Text)) {
            pct = qBound(0, QString::fromLocal8Bit(cap.readAll()).trimmed().toInt(), 100);
            break;
        }
    }
    if (pct != m_batteryPct) {
        m_batteryPct = pct;
        emit batteryPctChanged();
    }
}

QString ShellBackend::appNameForId(const QString &appId) const
{
    for (int i = 0; i < m_apps.rowCount(); ++i) {
        const QModelIndex idx = m_apps.index(i, 0);
        const QString file = m_apps.data(idx, AppModel::DesktopFileRole).toString();
        if (QFileInfo(file).completeBaseName().compare(appId, Qt::CaseInsensitive) == 0) {
            return m_apps.data(idx, AppModel::NameRole).toString();
        }
    }
    QString tail = appId.section(QLatin1Char('.'), -1);
    if (!tail.isEmpty()) {
        tail[0] = tail[0].toUpper();
    }
    return tail;
}

void ShellBackend::setActiveWindow(const QString &appId)
{
    const QString name = appId.isEmpty() ? QString() : appNameForId(appId);
    if (name != m_activeApp) {
        m_activeApp = name;
        emit activeAppChanged();
    }
}

void ShellBackend::setRunningApps(const QString &joined)
{
    QStringList next;
    const QStringList ids = joined.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    for (const QString &id : ids) {
        if (!next.contains(id, Qt::CaseInsensitive)) {
            next.append(id);
        }
    }
    if (next != m_runningApps) {
        m_runningApps = next;
        emit runningAppsChanged();
    }
}


void ShellBackend::toggleWifi()
{
    QProcess::startDetached(QStringLiteral("nmcli"),
                            { QStringLiteral("radio"), QStringLiteral("wifi"),
                              m_wifiEnabled ? QStringLiteral("off") : QStringLiteral("on") });
    QTimer::singleShot(500, this, &ShellBackend::refreshWifi);
}

void ShellBackend::powerAction(const QString &action)
{
    if (action == QLatin1String("poweroff")) {
        QProcess::startDetached(QStringLiteral("systemctl"), { QStringLiteral("poweroff") });
    } else if (action == QLatin1String("reboot")) {
        QProcess::startDetached(QStringLiteral("systemctl"), { QStringLiteral("reboot") });
    } else if (action == QLatin1String("suspend")) {
        QProcess::startDetached(QStringLiteral("systemctl"), { QStringLiteral("suspend") });
    } else if (action == QLatin1String("logout")) {
        QTimer::singleShot(0, qApp, &QCoreApplication::quit);
    }
}

void ShellBackend::refreshBluetooth()
{
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    QProcess p;
    p.start(QStringLiteral("bluetoothctl"), { QStringLiteral("show") });
    if (!p.waitForFinished(1500)) {
        return;
    }
    const QString out = QString::fromUtf8(p.readAllStandardOutput());
    if (out.isEmpty()) {
        m_hasBluetooth = false;
        if (m_bluetoothEnabled) {
            m_bluetoothEnabled = false;
            emit bluetoothEnabledChanged();
        }
        return;
    }
    m_hasBluetooth = true;
    const bool on = out.contains(QStringLiteral("Powered: yes"));
    if (on != m_bluetoothEnabled) {
        m_bluetoothEnabled = on;
        emit bluetoothEnabledChanged();
    }
}

void ShellBackend::toggleBluetooth()
{
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        m_bluetoothEnabled = !m_bluetoothEnabled;
        emit bluetoothEnabledChanged();
        return;
    }
    QProcess::startDetached(QStringLiteral("bluetoothctl"),
                            { QStringLiteral("power"),
                              m_bluetoothEnabled ? QStringLiteral("off")
                                                 : QStringLiteral("on") });
    QTimer::singleShot(500, this, &ShellBackend::refreshBluetooth);
}

void ShellBackend::refreshOutputDevices()
{
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    QProcess p;
    p.start(QStringLiteral("wpctl"), { QStringLiteral("status") });
    if (!p.waitForFinished(1500)) {
        return;
    }
    const QStringList lines = QString::fromUtf8(p.readAllStandardOutput()).split(QLatin1Char('\n'));
    bool inSinks = false;
    QVariantList devices;
    // Unanchored: wpctl status prefixes rows with box-drawing tree
    // characters (│, ├, ─), so the id column is not at line start.
    const QRegularExpression row(QStringLiteral("([*]?)\\s*(\\d+)\\.\\s+(\\S.*)$"));
    for (const QString &line : lines) {
        if (line.contains(QLatin1String("Sinks:"))) {
            inSinks = true;
            continue;
        }
        if (inSinks && (line.contains(QLatin1String("Sources:"))
                        || line.contains(QLatin1String("Devices:")))) {
            break;
        }
        if (!inSinks) {
            continue;
        }
        const QRegularExpressionMatch m = row.match(line);
        if (!m.hasMatch()) {
            continue;
        }
        QString name = m.captured(3).trimmed();
        const int bracket = name.indexOf(QLatin1String(" [vol:"));
        if (bracket > 0) {
            name = name.left(bracket).trimmed();
        }
        devices.append(QVariantMap{ { QStringLiteral("id"), m.captured(2).toInt() },
                                    { QStringLiteral("name"), name },
                                    { QStringLiteral("active"), m.captured(1) == QLatin1String("*") } });
    }
    if (devices != m_outputDevices) {
        m_outputDevices = devices;
        emit outputDevicesChanged();
    }
}

void ShellBackend::setOutputDevice(int id)
{
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        for (int i = 0; i < m_outputDevices.size(); ++i) {
            QVariantMap d = m_outputDevices[i].toMap();
            d[QStringLiteral("active")] = d[QStringLiteral("id")].toInt() == id;
            m_outputDevices[i] = d;
        }
        emit outputDevicesChanged();
        return;
    }
    QProcess::startDetached(QStringLiteral("wpctl"),
                            { QStringLiteral("set-default"), QString::number(id) });
    QTimer::singleShot(400, this, [this]() {
        refreshOutputDevices();
        refreshVolume();
    });
}

void ShellBackend::sendTestNotification()
{
    m_notifications->Notify(QStringLiteral("ix1"), 0, QString(),
                            QStringLiteral("ix1"), QStringLiteral("Test notification"),
                            {}, {}, 5000);
}

void ShellBackend::dismissNotification(uint id)
{
    m_notifications->CloseNotification(id);
}

void ShellBackend::setLauncherOpen(bool open)
{
    if (m_launcherOpen == open) {
        return;
    }
    m_launcherOpen = open;
    emit launcherOpenChanged();
}

void ShellBackend::setQuickSettingsOpen(bool open)
{
    if (m_qsOpen == open) {
        return;
    }
    m_qsOpen = open;
    if (open) {
        setCalendarOpen(false);
        if (!m_qsSection.isEmpty()) {
            // The target row's flash plays once per open, then the section clears.
            QTimer::singleShot(1400, this, [this]() {
                if (!m_qsSection.isEmpty()) {
                    m_qsSection.clear();
                    emit qsSectionChanged();
                }
            });
        }
    }
    emit quickSettingsOpenChanged();
}

void ShellBackend::toggleLauncher() { setLauncherOpen(!m_launcherOpen); }
void ShellBackend::toggleQuickSettings() { setQuickSettingsOpen(!m_qsOpen); }

void ShellBackend::openQuickSettings(const QString &section)
{
    m_qsSection = section;
    emit qsSectionChanged();
    setQuickSettingsOpen(true);
}

void ShellBackend::toggleCalendar() { setCalendarOpen(!m_calOpen); }

void ShellBackend::setCalendarOpen(bool open)
{
    if (m_calOpen == open) {
        return;
    }
    m_calOpen = open;
    if (open) {
        setQuickSettingsOpen(false);
    }
    emit calendarOpenChanged();
}

void ShellBackend::lock() { setLocked(true); }
void ShellBackend::unlock(const QString &password)
{
    if (verifyPassword(password)) {
        setLocked(false);
    }
}

void ShellBackend::onPrepareForSleep(bool goingDown)
{
    if (goingDown) {
        setLocked(true);
    }
}

void ShellBackend::setLocked(bool locked)
{
    if (m_locked == locked) {
        return;
    }
    m_locked = locked;
    emit lockedChanged();
}

bool ShellBackend::verifyPassword(const QString &password)
{
    // PAM verification against the "login" service.
    pam_handle_t *pamh = nullptr;
    QByteArray pw = password.toUtf8();

    struct pam_conv conv;
    struct pam_response *responses = nullptr;
    struct pam_message msg;

    auto convFn = [](int /*num_msg*/, const struct pam_message ** /*msg*/,
                     struct pam_response **resp, void *appdata) -> int {
        QByteArray *pw = static_cast<QByteArray *>(appdata);
        *resp = static_cast<struct pam_response *>(calloc(1, sizeof(struct pam_response)));
        if (!*resp) {
            return PAM_BUF_ERR;
        }
        (*resp)->resp = strdup(pw->constData());
        (*resp)->resp_retcode = 0;
        return PAM_SUCCESS;
    };

    conv.conv = convFn;
    conv.appdata_ptr = &pw;

    QByteArray service = QStringLiteral("login").toUtf8();
    QByteArray user = m_userName.toUtf8();
    if (pam_start(service.constData(), user.constData(), &conv, &pamh) != PAM_SUCCESS) {
        return false;
    }
    const int rc = pam_authenticate(pamh, 0);
    pam_end(pamh, rc == PAM_SUCCESS ? PAM_SUCCESS : PAM_AUTH_ERR);
    (void)responses;
    (void)msg;
    return rc == PAM_SUCCESS;
}
