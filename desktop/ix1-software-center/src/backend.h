#pragma once

#include <QAbstractListModel>
#include <QHash>
#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QVector>

// One Flatpak application entry (remote or installed).
struct FlatpakApp {
    QString id;
    QString name;
    QString summary;
    QString version;
    QString branch;
    QString arch;
    bool installed = false;
    // 0 = idle, 1 = operation in progress, 2 = operation failed
    int state = 0;
    QString permissions;
};

// List model over a filtered view of Flatpak apps.
class AppModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        SummaryRole,
        VersionRole,
        BranchRole,
        ArchRole,
        InstalledRole,
        StateRole,
        PermissionsRole,
    };

    explicit AppModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setApps(const QVector<FlatpakApp> &apps);
    void setFilter(const QString &filter);
    FlatpakApp *find(const QString &id);
    void updateEntry(const QString &id);

private:
    QVector<FlatpakApp> m_all;
    QVector<int> m_visible; // indices into m_all
    QString m_filter;

    bool matches(const FlatpakApp &app) const;
    void rebuild();
};

// Software Center backend: talks to Flatpak via its CLI (user installation).
class SoftwareCenterBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(bool remoteLoading READ remoteLoading NOTIFY remoteLoadingChanged)
    Q_PROPERTY(bool installedLoading READ installedLoading NOTIFY installedLoadingChanged)
    Q_PROPERTY(AppModel *remoteApps READ remoteApps CONSTANT)
    Q_PROPERTY(AppModel *installedApps READ installedApps CONSTANT)

public:
    explicit SoftwareCenterBackend(QObject *parent = nullptr);

    QString theme() const { return m_theme; }
    void setTheme(const QString &theme);

    QString statusText() const { return m_statusText; }
    bool remoteLoading() const { return m_remoteLoading; }
    bool installedLoading() const { return m_installedLoading; }

    AppModel *remoteApps() { return &m_remoteModel; }
    AppModel *installedApps() { return &m_installedModel; }

    Q_INVOKABLE void refreshRemote();
    Q_INVOKABLE void refreshInstalled();
    Q_INVOKABLE void setFilter(const QString &filter);
    Q_INVOKABLE void installApp(const QString &id);
    Q_INVOKABLE void removeApp(const QString &id);
    Q_INVOKABLE void updateApp(const QString &id);
    Q_INVOKABLE void updateAll();
    Q_INVOKABLE void launchApp(const QString &id);
    Q_INVOKABLE QVariantMap appDetails(const QString &id) const;

signals:
    void themeChanged();
    void statusTextChanged();
    void remoteLoadingChanged();
    void installedLoadingChanged();
    void operationFinished();

private:
    static QString configDir();
    void loadConfig();
    void saveConfig() const;
    void setStatus(const QString &text);
    void runProcess(const QStringList &args, int op, const QString &id);
    void startProcess(const QStringList &args, int op, const QString &id);
    void startNext();
    void parseListOutput(const QString &out, bool remote);
    void applyOpResult(bool ok, const QString &id, const QString &verb);

    QString m_theme = QStringLiteral("graphite");
    QString m_statusText;
    QString m_filter;
    bool m_remoteLoading = false;
    bool m_installedLoading = false;
    QVector<FlatpakApp> m_remote;
    QVector<FlatpakApp> m_installed;
    QHash<QString, FlatpakApp> m_installedById;
    AppModel m_remoteModel;
    AppModel m_installedModel;

    QProcess *m_proc = nullptr;
    QByteArray m_stdout;
    int m_op = 0; // 1=list-remote, 2=list-installed, 3=install, 4=remove, 5=update, 6=update-all
    QString m_opId;
    bool m_running = false;

    struct PendingOp {
        QStringList args;
        int op;
        QString id;
    };
    QVector<PendingOp> m_queue;
};
