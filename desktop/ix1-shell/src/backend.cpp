#include "backend.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

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
            this, &ShellBackend::notificationAdded);
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
    });

    // Signal and battery drift while the desktop sits idle.
    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(15000);
    connect(m_pollTimer, &QTimer::timeout, this, [this]() {
        refreshWifi();
        refreshBattery();
    });
    m_pollTimer->start();

    // Headless-render seeding (see IX1_SHOT_DIR in main.cpp).
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        m_wifiEnabled = true;
        m_wifiSignal = 78;
        m_batteryPct = 82;
        m_volume = 45;
        m_activeApp = QStringLiteral("Firefox");
        m_runningApps = { QStringLiteral("firefox") };
        if (qEnvironmentVariableIsSet("IX1_SHOW_CAL")) {
            m_calOpen = true;
        }
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
    bool got = !m_wifiEnabled;  // disabled radio is a definitive -1
    if (m_wifiEnabled) {
        QProcess s;
        s.start(QStringLiteral("nmcli"),
                { QStringLiteral("-t"), QStringLiteral("-f"),
                  QStringLiteral("IN-USE,SIGNAL"), QStringLiteral("dev"),
                  QStringLiteral("wifi") });
        if (s.waitForFinished(3000)) {
            got = true;
            const QStringList rows = QString::fromLocal8Bit(s.readAllStandardOutput())
                                         .split(QLatin1Char('\n'), Qt::SkipEmptyParts);
            for (const QString &row : rows) {
                // The AP in use is marked "*:<signal>".
                if (row.startsWith(QLatin1Char('*'))) {
                    signal = qBound(0, row.section(QLatin1Char(':'), -1).toInt(), 100);
                    break;
                }
            }
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
}

void ShellBackend::refreshBattery()
{
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

bool ShellBackend::isRunning(const QString &desktopFile) const
{
    const QString id = QFileInfo(desktopFile).completeBaseName();
    return m_runningApps.contains(id, Qt::CaseInsensitive);
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
