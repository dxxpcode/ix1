#include "backend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

#include <pwd.h>
#include <unistd.h>

#include <algorithm>

Backend::Backend(QObject *parent) : QObject(parent)
{
    // GECOS carries the full name the installer provisioned
    // (useradd -c); the first word is the greeting's name.
    if (const passwd *pw = getpwuid(getuid())) {
        const QString gecos = QString::fromLocal8Bit(pw->pw_gecos)
                                  .split(QLatin1Char(',')).first().trimmed();
        m_firstName = gecos.split(QLatin1Char(' ')).first();
    }
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        seedDemo();
        return;
    }
    rescan();
}

static QVariantMap net(const QString &ssid, int signal, bool secured, bool active)
{
    QVariantMap m;
    m[QStringLiteral("ssid")] = ssid;
    m[QStringLiteral("signal")] = signal;
    m[QStringLiteral("secured")] = secured;
    m[QStringLiteral("active")] = active;
    return m;
}

void Backend::seedDemo()
{
    // Render/smoke checks run where no wifi hardware exists; seed
    // representative rows so the screen can be captured.
    m_networks = {net(QStringLiteral("ix1-home"), 84, true, true),
                  net(QStringLiteral("coffeehouse-5g"), 62, true, false),
                  net(QStringLiteral("xfinitywifi"), 34, false, false)};
    m_connectedSsid = QStringLiteral("ix1-home");
    m_firstName = QStringLiteral("Alex");
    m_selectedNetwork = 0;
    emit networksChanged();
    emit connectedSsidChanged();
    emit selectedNetworkChanged();
}

void Backend::rescan()
{
    m_scanning = true;
    emit scanningChanged();

    // A rescan request is best-effort; the listing below is what matters.
    auto *rescan = new QProcess(this);
    connect(rescan, &QProcess::finished, this, [this, rescan]() {
        rescan->deleteLater();
        listNetworks();
    });
    rescan->start(QStringLiteral("nmcli"),
                  {QStringLiteral("dev"), QStringLiteral("wifi"),
                   QStringLiteral("rescan")});
}

void Backend::refresh() { listNetworks(); }

void Backend::listNetworks()
{
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int, QProcess::ExitStatus) {
        const QByteArray out = p->readAllStandardOutput();
        p->deleteLater();

        // nmcli terse output: SSID:SIGNAL:SECURITY:ACTIVE — ':' inside an
        // SSID is escaped as '\:', so split on unescaped colons only.
        // Fields stay raw bytes until the SSID needs to be a QString —
        // UTF-8 names (Café) must not go through per-byte Latin-1.
        QVariantList rows;
        for (const QByteArray &line : out.split('\n')) {
            if (line.isEmpty())
                continue;
            QList<QByteArray> fields;
            QByteArray cur;
            bool esc = false;
            for (const char c : line) {
                if (esc) { cur += c; esc = false; }
                else if (c == '\\') esc = true;
                else if (c == ':') { fields.append(cur); cur.clear(); }
                else cur += c;
            }
            fields.append(cur);
            if (fields.size() < 4 || fields[0].isEmpty())
                continue;
            const QString ssid = QString::fromUtf8(fields[0]);
            const bool active = fields[3] == QByteArrayLiteral("yes");
            rows << net(ssid, fields[1].toInt(),
                        !fields[2].isEmpty(), active);
            if (active)
                m_connectedSsid = ssid;
        }
        // Strongest first — the network you're most likely to want is
        // row one; the connected row keeps the lead regardless.
        std::stable_sort(rows.begin(), rows.end(), [](const QVariant &a,
                                                      const QVariant &b) {
            const QVariantMap ma = a.toMap(), mb = b.toMap();
            const bool aa = ma.value(QStringLiteral("active")).toBool();
            const bool ba = mb.value(QStringLiteral("active")).toBool();
            if (aa != ba)
                return aa;
            return ma.value(QStringLiteral("signal")).toInt()
                 > mb.value(QStringLiteral("signal")).toInt();
        });
        m_networks = rows;
        m_scanning = false;
        emit networksChanged();
        emit scanningChanged();
        emit connectedSsidChanged();

        if (m_selectedNetwork < 0 && !m_networks.isEmpty()) {
            m_selectedNetwork = 0;
            for (int i = 0; i < m_networks.size(); ++i)
                if (m_networks[i].toMap().value(QStringLiteral("active")).toBool()) {
                    m_selectedNetwork = i;
                    break;
                }
            emit selectedNetworkChanged();
        }
    });
    p->start(QStringLiteral("nmcli"),
             {QStringLiteral("-t"), QStringLiteral("-f"),
              QStringLiteral("SSID,SIGNAL,SECURITY,ACTIVE"),
              QStringLiteral("dev"), QStringLiteral("wifi"),
              QStringLiteral("list")});
}

QVariantMap Backend::networkAt(int i) const
{
    if (i < 0 || i >= m_networks.size())
        return {};
    return m_networks[i].toMap();
}

void Backend::previewNetwork(int i)
{
    if (i < 0 || i >= m_networks.size() || i == m_selectedNetwork)
        return;
    m_selectedNetwork = i;
    m_connectError.clear();
    m_failedSsid.clear();
    emit selectedNetworkChanged();
    emit connectErrorChanged();
    emit failedSsidChanged();
}

void Backend::setSelectedNetwork(int i)
{
    if (i < 0 || i >= m_networks.size())
        return;
    if (i == m_selectedNetwork) {
        // Re-tapping the already-selected row means "join": the listing
        // preselects row zero, so without this an open network that lands
        // in the default slot could never be connected at all.
        const QVariantMap n = networkAt(i);
        if (!n.value(QStringLiteral("secured")).toBool() &&
            !n.value(QStringLiteral("active")).toBool())
            connectSelected(QString());
        return;
    }
    m_selectedNetwork = i;
    m_connectError.clear();
    m_failedSsid.clear();
    emit selectedNetworkChanged();
    emit connectErrorChanged();
    emit failedSsidChanged();

    // Open networks join on tap — secured ones wait for the password.
    const QVariantMap n = networkAt(i);
    if (!n.value(QStringLiteral("secured")).toBool() &&
        !n.value(QStringLiteral("active")).toBool())
        connectSelected(QString());
}

void Backend::connectSelected(const QString &password)
{
    const QVariantMap n = networkAt(m_selectedNetwork);
    const QString ssid = n.value(QStringLiteral("ssid")).toString();
    if (ssid.isEmpty() || m_connectingSsid == ssid ||
        n.value(QStringLiteral("active")).toBool())
        return;

    m_connectError.clear();
    m_failedSsid.clear();
    emit connectErrorChanged();
    emit failedSsidChanged();
    m_connectingSsid = ssid;
    emit connectingSsidChanged();

    QStringList args{QStringLiteral("dev"), QStringLiteral("wifi"),
                     QStringLiteral("connect"), ssid};
    if (!password.isEmpty())
        args << QStringLiteral("password") << password;

    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this,
            [this, p, ssid](int code, QProcess::ExitStatus st) {
        const QByteArray out = p->readAllStandardOutput();
        const QByteArray err = p->readAllStandardError();
        p->deleteLater();
        m_connectingSsid.clear();
        emit connectingSsidChanged();
        if (st == QProcess::NormalExit && code == 0) {
            m_connectedSsid = ssid;
            emit connectedSsidChanged();
            refresh();
        } else {
            // nmcli puts the reason on stderr ("Error: ...").
            QString msg = QString::fromUtf8(err.isEmpty() ? out : err).trimmed();
            msg.remove(QStringLiteral("Error: "));
            m_connectError = msg.isEmpty()
                ? QStringLiteral("could not connect") : msg;
            m_failedSsid = ssid;
            emit connectErrorChanged();
            emit failedSsidChanged();
        }
    });
    p->start(QStringLiteral("nmcli"), args);
}

void Backend::finish()
{
    if (m_flagPath.isEmpty())
        return;
    QDir().mkpath(QFileInfo(m_flagPath).absolutePath());
    QFile f(m_flagPath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        f.write("done\n");
        f.close();
    }
}
