#ifndef IX1_ONBOARDING_BACKEND_H
#define IX1_ONBOARDING_BACKEND_H

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantList>

// Backend for the first-run onboarding UI: scans Wi-Fi via nmcli,
// connects the chosen network, and stamps the once-only marker.
class Backend : public QObject
{
    Q_OBJECT

    // Each entry: {ssid, signal (0-100), secured, active}.
    Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(int selectedNetwork READ selectedNetwork WRITE setSelectedNetwork
               NOTIFY selectedNetworkChanged)
    Q_PROPERTY(QString connectedSsid READ connectedSsid NOTIFY connectedSsidChanged)
    Q_PROPERTY(QString connectingSsid READ connectingSsid NOTIFY connectingSsidChanged)
    Q_PROPERTY(QString connectError READ connectError NOTIFY connectErrorChanged)

public:
    explicit Backend(QObject *parent = nullptr);

    QVariantList networks() const { return m_networks; }
    bool scanning() const { return m_scanning; }
    int selectedNetwork() const { return m_selectedNetwork; }
    void setSelectedNetwork(int i);
    QString connectedSsid() const { return m_connectedSsid; }
    QString connectingSsid() const { return m_connectingSsid; }
    QString connectError() const { return m_connectError; }

    void setFlagPath(const QString &p) { m_flagPath = p; }

    Q_INVOKABLE void rescan();                      // rescan + list
    Q_INVOKABLE void refresh();                     // list only
    Q_INVOKABLE void connectSelected(const QString &password);
    Q_INVOKABLE void finish();                      // stamp the marker

signals:
    void networksChanged();
    void scanningChanged();
    void selectedNetworkChanged();
    void connectedSsidChanged();
    void connectingSsidChanged();
    void connectErrorChanged();

private:
    void listNetworks();
    void seedDemo();
    QVariantMap networkAt(int i) const;

    QVariantList m_networks;
    bool m_scanning = false;
    int m_selectedNetwork = -1;
    QString m_connectedSsid;
    QString m_connectingSsid;
    QString m_connectError;
    QString m_flagPath;
    QProcess *m_proc = nullptr;
};

#endif
