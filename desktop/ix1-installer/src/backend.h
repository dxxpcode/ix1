#ifndef IX1_INSTALLER_BACKEND_H
#define IX1_INSTALLER_BACKEND_H

#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QVariantList>

// Backend for the ix1 installer UI: enumerates disks, runs the bootc
// install, and provisions the user account in the deployed system.
class Backend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList disks READ disks NOTIFY disksChanged)
    Q_PROPERTY(int selectedDisk READ selectedDisk WRITE setSelectedDisk NOTIFY selectedDiskChanged)
    Q_PROPERTY(bool encrypt READ encrypt WRITE setEncrypt NOTIFY encryptChanged)
    Q_PROPERTY(QString fullName READ fullName WRITE setFullName)
    Q_PROPERTY(QString userName READ userName WRITE setUserName)
    Q_PROPERTY(QString password READ password WRITE setPassword)
    Q_PROPERTY(QString luksPassphrase READ luksPassphrase WRITE setLuksPassphrase)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString progressText READ progressText NOTIFY progressTextChanged)
    Q_PROPERTY(QStringList logLines READ logLines NOTIFY logLinesChanged)
    Q_PROPERTY(bool installing READ installing NOTIFY installingChanged)
    Q_PROPERTY(bool done READ done NOTIFY doneChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    // Install image refs resolved at build time by the Containerfile
    // (written to /etc/ix1-install.conf), with CLI/env overrides.
    Q_PROPERTY(QString sourceImgref READ sourceImgref CONSTANT)
    Q_PROPERTY(QString targetImgref READ targetImgref CONSTANT)

public:
    explicit Backend(QObject *parent = nullptr);

    QVariantList disks() const { return m_disks; }
    int selectedDisk() const { return m_selectedDisk; }
    void setSelectedDisk(int i);
    bool encrypt() const { return m_encrypt; }
    void setEncrypt(bool v);
    QString fullName() const { return m_fullName; }
    void setFullName(const QString &v) { m_fullName = v; }
    void setUserName(const QString &v) { m_userName = v; }
    QString userName() const { return m_userName; }
    void setPassword(const QString &v) { m_password = v; }
    QString password() const { return m_password; }
    void setLuksPassphrase(const QString &v) { m_luksPass = v; }
    QString luksPassphrase() const { return m_luksPass; }
    int progress() const { return m_progress; }
    QString progressText() const { return m_progressText; }
    QStringList logLines() const { return m_logLines; }
    bool installing() const { return m_installing; }
    bool done() const { return m_done; }
    QString error() const { return m_error; }
    QString sourceImgref() const { return m_sourceImgref; }
    QString targetImgref() const { return m_targetImgref; }

    Q_INVOKABLE void refreshDisks();
    Q_INVOKABLE void startInstall();
    Q_INVOKABLE void reboot();

signals:
    void disksChanged();
    void selectedDiskChanged();
    void encryptChanged();
    void progressChanged();
    void progressTextChanged();
    void logLinesChanged();
    void installingChanged();
    void doneChanged();
    void errorChanged();

private:
    void enumerateDisks();
    void setProgress(int pct, const QString &text);
    void appendLog(const QString &line, bool active = false);
    bool runStep(const QString &desc, int pctBefore, const QString &cmd,
                 const QStringList &args, QString *out = nullptr,
                 const QString &stdinText = QString());
    bool provisionUser(const QString &rootMount);
    void fail(const QString &msg);

    QVariantList m_disks;
    int m_selectedDisk = -1;
    bool m_encrypt = false;
    QString m_fullName, m_userName, m_password, m_luksPass;
    int m_progress = 0;
    QString m_progressText;
    QStringList m_logLines;
    bool m_installing = false;
    bool m_done = false;
    QString m_error;
    QString m_sourceImgref, m_targetImgref;
    QProcess *m_proc = nullptr;
};

#endif
