#include "backend.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>
#include <QTextStream>
#include <sys/utsname.h>
#include <QFileInfo>
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
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        m_brightness = 68;
        m_batteryPct = 82;
        m_wallpapers = {
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("graphite") },
                         { QStringLiteral("path"), QStringLiteral("demo:graphite") } },
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("aurora") },
                         { QStringLiteral("path"), QStringLiteral("demo:aurora") } },
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("dusk") },
                         { QStringLiteral("path"), QStringLiteral("demo:dusk") } },
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("wave") },
                         { QStringLiteral("path"), QStringLiteral("demo:wave") } },
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("morning") },
                         { QStringLiteral("path"), QStringLiteral("demo:morning") } },
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("porcelain") },
                         { QStringLiteral("path"), QStringLiteral("demo:porcelain") } },
        };
        m_wallpaper = QStringLiteral("demo:graphite");
        m_displays = {
            QVariantMap{ { QStringLiteral("name"), QStringLiteral("eDP-1") },
                         { QStringLiteral("current"), QStringLiteral("1920x1080@60") },
                         { QStringLiteral("modes"), QStringList{ QStringLiteral("2560x1440@60"),
                               QStringLiteral("1920x1080@60"), QStringLiteral("1680x1050@60"),
                               QStringLiteral("1440x900@60"), QStringLiteral("1280x800@60") } },
                         { QStringLiteral("scale"), 1.0 } },
        };
        emit wallpapersChanged();
        emit displaysChanged();
        emit brightnessChanged();
        emit batteryPctChanged();
        emit wallpaperChanged();
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
    // Parse "key=value" lines. This app owns theme=/wallpaper=/idleLock=/
    // idleSuspend=; the shell owns dnd=/dockPinned=.
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
            } else if (line.startsWith(QLatin1String("wallpaper="))) {
                m_wallpaper = line.mid(10).trimmed();
            } else if (line.startsWith(QLatin1String("idleLock="))) {
                const int v = line.mid(9).trimmed().toInt();
                if (v >= 0) {
                    m_idleLockMin = v;
                }
            } else if (line.startsWith(QLatin1String("idleSuspend="))) {
                const int v = line.mid(12).trimmed().toInt();
                if (v >= 0) {
                    m_idleSuspendMin = v;
                }
            }
        }
    }
}

void SettingsBackend::saveConfig() const
{
    // settings.conf is shared — the shell persists keys like dnd= there.
    // Rewrite only this app's lines, preserving everything else.
    const QString path = configDir() + QStringLiteral("/settings.conf");
    const QStringList owned = { QStringLiteral("theme"), QStringLiteral("wallpaper"),
                                QStringLiteral("idleLock"), QStringLiteral("idleSuspend") };
    QStringList lines;
    bool wrote = false;
    QFile f(path);
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&f);
        while (!in.atEnd()) {
            const QString line = in.readLine().trimmed();
            if (line.isEmpty()) {
                continue;
            }
            bool ownedLine = false;
            for (const QString &key : owned) {
                if (line.startsWith(key + QLatin1String("="))) {
                    if (!wrote) {
                        lines << QStringLiteral("theme=%1").arg(m_theme)
                              << QStringLiteral("wallpaper=%1").arg(m_wallpaper)
                              << QStringLiteral("idleLock=%1").arg(m_idleLockMin)
                              << QStringLiteral("idleSuspend=%1").arg(m_idleSuspendMin);
                        wrote = true;
                    }
                    ownedLine = true;
                    break;
                }
            }
            if (!ownedLine) {
                lines << line;
            }
        }
    }
    if (!wrote) {
        lines.prepend(QStringLiteral("idleSuspend=%1").arg(m_idleSuspendMin));
        lines.prepend(QStringLiteral("idleLock=%1").arg(m_idleLockMin));
        if (!m_wallpaper.isEmpty()) {
            lines.prepend(QStringLiteral("wallpaper=%1").arg(m_wallpaper));
        }
        lines.prepend(QStringLiteral("theme=%1").arg(m_theme));
    }
    writeFile(path, lines.join(QLatin1Char('\n')) + QLatin1Char('\n'));
}

// ---- Wallpaper -------------------------------------------------------------

void SettingsBackend::refreshWallpapers()
{
    // IX1_DEMO seeds fixed values for headless renders; real scans would
    // overwrite them.
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    QStringList dirs;
    for (const QString &base : QStandardPaths::standardLocations(QStandardPaths::AppDataLocation)) {
        const QString wdir = base + QStringLiteral("/wallpapers");
        if (QFileInfo(wdir).isDir()) {
            dirs << wdir;
        }
    }
    // The image puts the shipped set here; AppDataLocation covers it too but
    // list it explicitly so builds outside the image still find them.
    const QString systemDir = QStringLiteral("/usr/share/ix1/wallpapers");
    if (QFileInfo(systemDir).isDir() && !dirs.contains(systemDir)) {
        dirs.prepend(systemDir);
    }

    QVariantList list;
    QStringList seen;
    for (const QString &dirPath : dirs) {
        const QDir dir(dirPath);
        const auto files = dir.entryInfoList({ QStringLiteral("*.png"), QStringLiteral("*.jpg"),
                                               QStringLiteral("*.jpeg") },
                                             QDir::Files, QDir::Name);
        for (const QFileInfo &fi : files) {
            if (seen.contains(fi.completeBaseName())) {
                continue;
            }
            seen << fi.completeBaseName();
            list << QVariantMap{
                { QStringLiteral("name"), fi.completeBaseName() },
                { QStringLiteral("path"), fi.absoluteFilePath() },
            };
        }
    }
    m_wallpapers = list;
    emit wallpapersChanged();
}

void SettingsBackend::setWallpaper(const QString &path)
{
    if (path == m_wallpaper) {
        return;
    }
    m_wallpaper = path;
    saveConfig();
    emit wallpaperChanged();
}

// ---- Display ---------------------------------------------------------------
// kscreen-doctor -j prints the outputs' JSON; mode ids and names come from it,
// applies are `kscreen-doctor output.<name>.<verb>.<value>`.

void SettingsBackend::refreshDisplays()
{
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    QProcess p;
    p.start(QStringLiteral("kscreen-doctor"), { QStringLiteral("-j") });
    QVariantList list;
    if (p.waitForFinished(5000) && p.exitCode() == 0) {
        const QJsonDocument doc = QJsonDocument::fromJson(p.readAllStandardOutput());
        const QJsonArray outs = doc.object().value(QStringLiteral("outputs")).toArray();
        for (const QJsonValue &v : outs) {
            const QJsonObject out = v.toObject();
            const QString name = out.value(QStringLiteral("name")).toString();
            const int currentId = out.value(QStringLiteral("currentModeId")).toVariant().toInt();
            QStringList modes;
            QString current;
            const QJsonArray modeArr = out.value(QStringLiteral("modes")).toArray();
            for (const QJsonValue &mv : modeArr) {
                const QJsonObject mode = mv.toObject();
                const QString label = mode.value(QStringLiteral("name")).toString();
                if (!label.isEmpty()) {
                    modes << label;
                    if (mode.value(QStringLiteral("id")).toVariant().toInt() == currentId) {
                        current = label;
                    }
                }
            }
            if (name.isEmpty() || modes.isEmpty()) {
                continue;
            }
            list << QVariantMap{
                { QStringLiteral("name"), name },
                { QStringLiteral("current"), current },
                { QStringLiteral("modes"), modes },
                { QStringLiteral("scale"), out.value(QStringLiteral("scale")).toDouble(1.0) },
            };
        }
    }
    if (list != m_displays) {
        m_displays = list;
        emit displaysChanged();
    }
}

void SettingsBackend::setDisplayMode(const QString &name, const QString &mode)
{
    QProcess::startDetached(QStringLiteral("kscreen-doctor"),
                            { QStringLiteral("output.%1.mode.%2").arg(name, mode) });
    QTimer::singleShot(800, this, &SettingsBackend::refreshDisplays);
}

void SettingsBackend::setDisplayScale(const QString &name, double scale)
{
    QProcess::startDetached(QStringLiteral("kscreen-doctor"),
                            { QStringLiteral("output.%1.scale.%2").arg(name).arg(scale) });
    QTimer::singleShot(800, this, &SettingsBackend::refreshDisplays);
}

// ---- Power -----------------------------------------------------------------

void SettingsBackend::refreshPower()
{
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        return;
    }
    const QDir dir(QStringLiteral("/sys/class/backlight"));
    const QStringList devs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    if (!devs.isEmpty()) {
        const QString dev = devs.constFirst();
        QFile bf(dir.filePath(dev + QStringLiteral("/brightness")));
        QFile mf(dir.filePath(dev + QStringLiteral("/max_brightness")));
        if (bf.open(QIODevice::ReadOnly) && mf.open(QIODevice::ReadOnly)) {
            const int cur = QString::fromUtf8(bf.readAll()).trimmed().toInt();
            const int max = QString::fromUtf8(mf.readAll()).trimmed().toInt();
            if (max > 0) {
                const int pct = qBound(0, qRound(cur * 100.0 / max), 100);
                if (pct != m_brightness) {
                    m_brightness = pct;
                    emit brightnessChanged();
                }
            }
        }
    }

    const QDir ps(QStringLiteral("/sys/class/power_supply"));
    const QStringList bats = ps.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &b : bats) {
        QFile cf(ps.filePath(b + QStringLiteral("/capacity")));
        if (cf.open(QIODevice::ReadOnly)) {
            const int pct = QString::fromUtf8(cf.readAll()).trimmed().toInt();
            if (pct >= 0 && pct != m_batteryPct) {
                m_batteryPct = pct;
                emit batteryPctChanged();
            }
            break;
        }
    }
}

void SettingsBackend::setBrightness(int percent)
{
    const QDir dir(QStringLiteral("/sys/class/backlight"));
    const QStringList devs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    if (devs.isEmpty()) {
        return;
    }
    QFile mf(dir.filePath(devs.constFirst() + QStringLiteral("/max_brightness")));
    if (!mf.open(QIODevice::ReadOnly)) {
        return;
    }
    const int max = QString::fromUtf8(mf.readAll()).trimmed().toInt();
    const int raw = qBound(0, qRound(qBound(0, percent, 100) * max / 100.0), max);
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.login1"),
        QStringLiteral("/org/freedesktop/login1/session/auto"),
        QStringLiteral("org.freedesktop.login1.Session"),
        QStringLiteral("SetBrightness"));
    msg << QStringLiteral("backlight") << devs.constFirst() << quint32(raw);
    QDBusConnection::systemBus().asyncCall(msg);
    if (m_brightness != percent) {
        m_brightness = percent;
        emit brightnessChanged();
    }
}

void SettingsBackend::setIdleLockMinutes(int minutes)
{
    if (minutes < 0 || minutes == m_idleLockMin) {
        return;
    }
    m_idleLockMin = minutes;
    saveConfig();
    emit idleLockChanged();
}

void SettingsBackend::setIdleSuspendMinutes(int minutes)
{
    if (minutes < 0 || minutes == m_idleSuspendMin) {
        return;
    }
    m_idleSuspendMin = minutes;
    saveConfig();
    emit idleSuspendChanged();
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
    refreshWallpapers();
    refreshDisplays();
    refreshPower();
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
