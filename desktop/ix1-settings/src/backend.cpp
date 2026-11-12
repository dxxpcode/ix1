#include "backend.h"

#include <QDir>
#include <QFile>
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
