#include "backend.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <pwd.h>
#include <security/pam_appl.h>
#include <unistd.h>

#include "notifications.h"

namespace {

QStringList desktopEntryPaths()
{
    QStringList dirs = {
        QStringLiteral("/usr/local/share/applications"),
        QStringLiteral("/usr/share/applications"),
        QDir::homePath() + QStringLiteral("/.local/share/applications"),
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
    });
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
        emit wifiEnabledChanged();
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
