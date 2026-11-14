#include "backend.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
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
    QTimer::singleShot(0, this, [this]() {
        refreshVolume();
        refreshWifi();
        refreshBluetooth();
        refreshBrightness();
    });

    // Bluetooth controllers can appear after login (e.g. USB dongles) — poll
    // so the Quick Settings tile shows up without a shell restart.
    auto *btPoll = new QTimer(this);
    connect(btPoll, &QTimer::timeout, this, &ShellBackend::refreshBluetooth);
    btPoll->start(5000);

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
        m_wifiEnabled = (out == QLatin1String("enabled"));
    }

    QString ssid;
    if (m_wifiEnabled) {
        QProcess a;
        a.start(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("-f"),
                                            QStringLiteral("ACTIVE,SSID"), QStringLiteral("dev"),
                                            QStringLiteral("wifi"), QStringLiteral("list") });
        if (a.waitForFinished(3000)) {
            const QStringList lines = QString::fromLocal8Bit(a.readAllStandardOutput()).split(QLatin1Char('\n'));
            for (const QString &line : lines) {
                if (line.startsWith(QLatin1String("yes:"))) {
                    ssid = line.mid(4).trimmed();
                    break;
                }
            }
        }
    }
    m_wifiName = ssid;
    emit wifiChanged();
}

void ShellBackend::toggleWifi()
{
    QProcess::startDetached(QStringLiteral("nmcli"),
                            { QStringLiteral("radio"), QStringLiteral("wifi"),
                              m_wifiEnabled ? QStringLiteral("off") : QStringLiteral("on") });
    QTimer::singleShot(500, this, &ShellBackend::refreshWifi);
}

void ShellBackend::refreshBluetooth()
{
    // Controller presence is instant via sysfs — no subprocess on the UI
    // thread (this runs on a 5s poll timer; a stalled bluez must not freeze
    // the shell or the lock screen).
    const bool available = !QDir(QStringLiteral("/sys/class/bluetooth"))
                                .entryList(QDir::Dirs | QDir::NoDotAndDotDot)
                                .isEmpty();
    bool changed = available != m_btAvailable;
    m_btAvailable = available;
    if (!available && m_btEnabled) {
        m_btEnabled = false;
        changed = true;
    }
    if (changed) {
        emit bluetoothChanged();
    }
    if (!available || m_btProbe != nullptr) {
        return;
    }

    // Powered state needs bluetoothctl — run it async, one probe at a time.
    auto *p = new QProcess(this);
    m_btProbe = p;
    connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, p](int, QProcess::ExitStatus) {
        m_btProbe = nullptr;
        const bool powered = QString::fromLocal8Bit(p->readAllStandardOutput())
                                 .contains(QLatin1String("Powered: yes"));
        p->deleteLater();
        if (powered != m_btEnabled) {
            m_btEnabled = powered;
            emit bluetoothChanged();
        }
    });
    // FailedToStart emits errorOccurred, never finished — release the guard.
    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError) {
        m_btProbe = nullptr;
        p->deleteLater();
    });
    p->start(QStringLiteral("bluetoothctl"), { QStringLiteral("show") });
}

void ShellBackend::toggleBluetooth()
{
    if (!m_btAvailable) {
        return;
    }
    QProcess::startDetached(QStringLiteral("bluetoothctl"),
                            { QStringLiteral("power"),
                              m_btEnabled ? QStringLiteral("off") : QStringLiteral("on") });
    QTimer::singleShot(500, this, &ShellBackend::refreshBluetooth);
}

void ShellBackend::refreshBrightness()
{
    // Real backlight via sysfs; absent on VMs — the module hides then.
    const QDir bl(QStringLiteral("/sys/class/backlight"));
    const QStringList devs = bl.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    if (devs.isEmpty()) {
        if (m_brightnessAvailable) {
            m_brightnessAvailable = false;
            m_brightness = -1;
            emit brightnessChanged();
        }
        return;
    }

    m_backlightDevice = devs.constFirst();
    QFile maxF(bl.absoluteFilePath(m_backlightDevice + QStringLiteral("/max_brightness")));
    QFile curF(bl.absoluteFilePath(m_backlightDevice + QStringLiteral("/brightness")));
    if (!maxF.open(QIODevice::ReadOnly) || !curF.open(QIODevice::ReadOnly)) {
        return;
    }
    m_backlightMax = QString::fromLocal8Bit(maxF.readAll()).trimmed().toInt();
    const int cur = QString::fromLocal8Bit(curF.readAll()).trimmed().toInt();
    m_brightnessAvailable = m_backlightMax > 0;
    m_brightness = m_backlightMax > 0 ? qBound(0, qRound(cur * 100.0 / m_backlightMax), 100) : -1;
    emit brightnessChanged();
}

void ShellBackend::setBrightness(int percent)
{
    if (!m_brightnessAvailable) {
        return;
    }
    const int raw = qRound(qBound(0, percent, 100) * m_backlightMax / 100.0);
    QFile f(QDir(QStringLiteral("/sys/class/backlight"))
                .absoluteFilePath(m_backlightDevice + QStringLiteral("/brightness")));
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(QByteArray::number(raw));
        f.close();
    } else {
        // sysfs brightness files are root-owned on most hardware; logind's
        // SetBrightness is polkit-authorized for the active local session.
        QDBusMessage msg = QDBusMessage::createMethodCall(
            QStringLiteral("org.freedesktop.login1"),
            QStringLiteral("/org/freedesktop/login1/session/self"),
            QStringLiteral("org.freedesktop.login1.Session"),
            QStringLiteral("SetBrightness"));
        msg << QStringLiteral("backlight") << m_backlightDevice << static_cast<uint>(raw);
        QDBusConnection::systemBus().call(msg);
    }
    QTimer::singleShot(150, this, &ShellBackend::refreshBrightness);
}

void ShellBackend::setDnd(bool on)
{
    if (m_dnd == on) {
        return;
    }
    m_dnd = on;
    emit dndChanged();
}

void ShellBackend::toggleTheme()
{
    const QString path = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                         + QStringLiteral("/ix1/settings.conf");
    const QString next = m_theme == QLatin1String("graphite")
        ? QStringLiteral("porcelain") : QStringLiteral("graphite");

    QStringList lines;
    bool wrote = false;
    QFile in(path);
    if (in.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream ts(&in);
        while (!ts.atEnd()) {
            const QString line = ts.readLine();
            if (line.startsWith(QLatin1String("theme="))) {
                lines.append(QStringLiteral("theme=") + next);
                wrote = true;
            } else {
                lines.append(line);
            }
        }
        in.close();
    }
    if (!wrote) {
        lines.append(QStringLiteral("theme=") + next);
    }

    QFile out(path);
    if (out.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        QTextStream ts(&out);
        for (const QString &line : lines) {
            ts << line << '\n';
        }
    }
    // loadTheme() picks the file up via m_configWatcher.
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
    emit quickSettingsOpenChanged();
}

void ShellBackend::toggleLauncher() { setLauncherOpen(!m_launcherOpen); }
void ShellBackend::toggleQuickSettings() { setQuickSettingsOpen(!m_qsOpen); }

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
