#include "backend.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>
#include <QTextStream>
#include <sys/utsname.h>
#include <unistd.h>

namespace {

bool writeFile(const QString &path, const QString &content)
{
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        return false;
    }
    f.write(content.toUtf8());
    return true;
}

} // namespace

SettingsBackend::SettingsBackend(QObject *parent)
    : QObject(parent)
{
    loadConfig();
    {
        struct utsname u{};
        if (::uname(&u) == 0) {
            m_hostName = QString::fromLocal8Bit(u.nodename);
            m_kernelVersion = QString::fromLocal8Bit(u.release);
        }
    }
    {
        QFile f(QStringLiteral("/etc/ix1-release"));
        if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QString v = QString::fromUtf8(f.readAll()).trimmed();
            if (!v.isEmpty()) {
                m_osRelease = v;
            }
        }
    }
    refresh();
}

QString SettingsBackend::configDir()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                        + QStringLiteral("/ix1");
    QDir().mkpath(dir);
    return dir;
}

void SettingsBackend::loadConfig()
{
    // Parse "key=value" lines; theme is the only persisted key.
    QFile f(configDir() + QStringLiteral("/settings.conf"));
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&f);
        while (!in.atEnd()) {
            const QString line = in.readLine().trimmed();
            if (line.startsWith(QLatin1String("theme="))) {
                const QString value = line.mid(6).trimmed();
                if (value == QLatin1String("porcelain") || value == QLatin1String("graphite")) {
                    m_theme = value;
                }
            }
        }
    }
}

void SettingsBackend::saveConfig() const
{
    writeFile(configDir() + QStringLiteral("/settings.conf"),
              QStringLiteral("theme=%1\n").arg(m_theme));
}

void SettingsBackend::setTheme(const QString &theme)
{
    if (theme != QLatin1String("graphite") && theme != QLatin1String("porcelain")) {
        return;
    }
    if (m_theme == theme) {
        return;
    }
    m_theme = theme;
    saveConfig();
    emit themeChanged();
}

void SettingsBackend::refreshVolume()
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

void SettingsBackend::setVolume(int percent)
{
    const int clamped = qBound(0, percent, 150);
    QProcess::startDetached(QStringLiteral("wpctl"),
                            { QStringLiteral("set-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@"),
                              QStringLiteral("%1%").arg(clamped) });
    QTimer::singleShot(150, this, &SettingsBackend::refreshVolume);
}

void SettingsBackend::refreshWifi()
{
    QProcess p;
    p.start(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("WIFI"),
                                        QStringLiteral("radio") });
    if (p.waitForFinished(2000)) {
        m_wifiEnabled = QString::fromLocal8Bit(p.readAllStandardOutput()).trimmed() == QLatin1String("enabled");
        emit wifiEnabledChanged();
    }

    QProcess::startDetached(QStringLiteral("nmcli"), { QStringLiteral("device"), QStringLiteral("wifi"),
                                                       QStringLiteral("rescan") });
    QProcess l;
    l.start(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("-f"),
                                       QStringLiteral("NAME,TYPE"), QStringLiteral("connection"),
                                       QStringLiteral("show"), QStringLiteral("--active") });
    QString activeWifi;
    if (l.waitForFinished(2000)) {
        QTextStream in(&l);
        while (!in.atEnd()) {
            const QStringList parts = in.readLine().split(QLatin1Char(':'));
            if (parts.size() == 2 && parts.at(1).trimmed() == QLatin1String("802-11-wireless")) {
                activeWifi = parts.at(0).trimmed();
                break;
            }
        }
    }
    if (activeWifi != m_wifiSsid) {
        m_wifiSsid = activeWifi;
        emit wifiSsidChanged();
    }

    QProcess w;
    w.start(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("-f"),
                                       QStringLiteral("SSID,SIGNAL,SECURITY,ACTIVE"),
                                       QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("list") });
    QStringList networks;
    if (w.waitForFinished(8000)) {
        QTextStream in(&w);
        while (!in.atEnd()) {
            const QString line = in.readLine();
            if (line.isEmpty()) {
                continue;
            }
            networks.append(line);
        }
    }
    m_wifiNetworks = networks;
    emit wifiNetworksChanged();
}

void SettingsBackend::setWifiEnabled(bool enabled)
{
    QProcess::startDetached(QStringLiteral("nmcli"),
                            { QStringLiteral("radio"), QStringLiteral("wifi"),
                              enabled ? QStringLiteral("on") : QStringLiteral("off") });
    QTimer::singleShot(500, this, &SettingsBackend::refreshWifi);
}

void SettingsBackend::connectWifi(const QString &ssid, const QString &password)
{
    QStringList args = { QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("connect"), ssid };
    if (!password.isEmpty()) {
        args << QStringLiteral("password") << password;
    }
    QProcess::startDetached(QStringLiteral("nmcli"), args);
    QTimer::singleShot(3000, this, &SettingsBackend::refreshWifi);
}

void SettingsBackend::forgetWifi(const QString &ssid)
{
    QProcess::startDetached(QStringLiteral("nmcli"),
                            { QStringLiteral("connection"), QStringLiteral("delete"), ssid });
    QTimer::singleShot(1000, this, &SettingsBackend::refreshWifi);
}

void SettingsBackend::refresh()
{
    refreshVolume();
    refreshWifi();
}

void SettingsBackend::setUpdateStatus(const QString &status)
{
    if (m_updateStatus == status) {
        return;
    }
    m_updateStatus = status;
    emit updateStatusChanged();
}

void SettingsBackend::setUpdateBusy(bool busy)
{
    if (m_updateBusy == busy) {
        return;
    }
    m_updateBusy = busy;
    emit updateBusyChanged();
}

// bootc status --json needs root, so it runs through the pkexec helper.
// status.booted / status.staged / status.rollback are deployment objects
// (or null); each carries image.image.image = image ref.
void SettingsBackend::refreshUpdates()
{
    QProcess p;
    p.start(QStringLiteral("pkexec"), { QStringLiteral("/usr/libexec/ix1-update"),
                                        QStringLiteral("status") });
    if (p.waitForFinished(8000) && p.exitCode() == 0) {
        const QJsonDocument doc = QJsonDocument::fromJson(p.readAllStandardOutput());
        const QJsonObject status = doc.object()
                                     .value(QStringLiteral("status")).toObject();
        const QJsonObject booted = status.value(QStringLiteral("booted")).toObject();
        const QString image = booted.value(QStringLiteral("image")).toObject()
                                  .value(QStringLiteral("image")).toObject()
                                  .value(QStringLiteral("image")).toString();
        // Deployments are objects when present; JSON null (and a missing key
        // on error) are both non-objects, so isObject() is the correct test.
        const bool staged = status.value(QStringLiteral("staged")).isObject();
        const bool rollback = status.value(QStringLiteral("rollback")).isObject();
        if (!image.isEmpty()) {
            m_osImage = image;
        }
        m_updateStaged = staged;
        m_rollbackAvailable = rollback;
        emit updatesChanged();
    } else {
        // Failed/denied probes must not clear deployment state; surface the
        // helper's stderr (e.g. a pkexec auth rejection) instead.
        const QString tail = QString::fromLocal8Bit(p.readAllStandardError())
                                 .trimmed()
                                 .split(QLatin1Char('\n'))
                                 .last();
        setUpdateStatus(tail.isEmpty() ? QStringLiteral("Could not read update status")
                                       : tail);
    }

    QProcess f;
    f.start(QStringLiteral("flatpak"), { QStringLiteral("remote-ls"), QStringLiteral("--user"),
                                         QStringLiteral("--updates") });
    if (f.waitForFinished(8000) && f.exitCode() == 0) {
        int count = 0;
        QTextStream in(&f);
        while (!in.atEnd()) {
            if (!in.readLine().trimmed().isEmpty()) {
                ++count;
            }
        }
        m_flatpakUpdateCount = count;
    } else {
        // -1 means "not probed yet"; -2 means the probe failed.
        m_flatpakUpdateCount = -2;
    }
    emit flatpakUpdateCountChanged();
}

// Long-running privileged ops run through pkexec + the ix1-update helper
// (polkit rule 50-ix1-updates.rules grants active wheel users).
void SettingsBackend::startUpdateOp(const QStringList &program, int kind)
{
    if (m_updateProc) {
        return;
    }
    m_updateOpKind = kind;
    m_updateProc = new QProcess(this);
    connect(m_updateProc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus) {
        const QString tail = QString::fromLocal8Bit(m_updateProc->readAllStandardOutput()
                                                    + m_updateProc->readAllStandardError())
                                 .trimmed()
                                 .split(QLatin1Char('\n'))
                                 .last();
        switch (m_updateOpKind) {
        case 1: // check — show bootc's own verdict line
            // ("No changes in: docker://…" or the new version queued).
            setUpdateStatus(!tail.isEmpty() ? tail
                                            : (exitCode == 0
                                                   ? QStringLiteral("Update check complete")
                                                   : QStringLiteral("Update check failed")));
            break;
        case 2: // upgrade
            setUpdateStatus(exitCode == 0
                                ? (tail.startsWith(QStringLiteral("No changes"))
                                       ? QStringLiteral("System is up to date")
                                       : QStringLiteral("Update staged — restart to apply"))
                                : (tail.isEmpty() ? QStringLiteral("Update failed")
                                                  : tail));
            break;
        case 3: // rollback
            setUpdateStatus(exitCode == 0
                                ? QStringLiteral("Previous deployment restored — restart to boot it")
                                : (tail.isEmpty() ? QStringLiteral("Rollback failed")
                                                  : tail));
            break;
        case 4: // flatpak update
            setUpdateStatus(exitCode == 0 ? QStringLiteral("Applications updated")
                                        : (tail.isEmpty() ? QStringLiteral("App update failed")
                                                          : tail));
            break;
        }
        m_updateProc->deleteLater();
        m_updateProc = nullptr;
        setUpdateBusy(false);
        refreshUpdates();
    });
    QStringList args = program;
    m_updateProc->start(args.takeFirst(), args);
    setUpdateBusy(true);
}

void SettingsBackend::checkOsUpdate()
{
    setUpdateStatus(QStringLiteral("Checking for updates…"));
    startUpdateOp({ QStringLiteral("pkexec"), QStringLiteral("/usr/libexec/ix1-update"),
                    QStringLiteral("check") }, 1);
}

void SettingsBackend::stageOsUpdate()
{
    setUpdateStatus(QStringLiteral("Downloading and staging update…"));
    startUpdateOp({ QStringLiteral("pkexec"), QStringLiteral("/usr/libexec/ix1-update"),
                    QStringLiteral("upgrade") }, 2);
}

void SettingsBackend::rollbackOs()
{
    setUpdateStatus(QStringLiteral("Rolling back to previous deployment…"));
    startUpdateOp({ QStringLiteral("pkexec"), QStringLiteral("/usr/libexec/ix1-update"),
                    QStringLiteral("rollback") }, 3);
}

void SettingsBackend::rebootSystem()
{
    QProcess::startDetached(QStringLiteral("pkexec"),
                            { QStringLiteral("/usr/libexec/ix1-update"),
                              QStringLiteral("reboot") });
}

void SettingsBackend::updateFlatpakApps()
{
    setUpdateStatus(QStringLiteral("Updating applications…"));
    startUpdateOp({ QStringLiteral("flatpak"), QStringLiteral("--user"),
                    QStringLiteral("update"), QStringLiteral("-y") }, 4);
}

void SettingsBackend::openSoftwareCenter()
{
    QProcess::startDetached(QStringLiteral("ix1-software-center"), {});
}
