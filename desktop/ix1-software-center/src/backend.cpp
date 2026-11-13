#include "backend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QTextStream>
#include <QTimer>

namespace {

QStringList splitTabs(const QString &line)
{
    return line.split(QLatin1Char('\t'));
}

} // namespace

// ---------------------------------------------------------------- AppModel

AppModel::AppModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int AppModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : static_cast<int>(m_visible.size());
}

QVariant AppModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visible.size()) {
        return {};
    }
    const FlatpakApp &app = m_all.at(m_visible.at(index.row()));
    switch (role) {
    case IdRole: return app.id;
    case NameRole: return app.name;
    case SummaryRole: return app.summary;
    case VersionRole: return app.version;
    case BranchRole: return app.branch;
    case ArchRole: return app.arch;
    case InstalledRole: return app.installed;
    case StateRole: return app.state;
    case PermissionsRole: return app.permissions;
    }
    return {};
}

QHash<int, QByteArray> AppModel::roleNames() const
{
    return {
        { IdRole, "id" },
        { NameRole, "name" },
        { SummaryRole, "summary" },
        { VersionRole, "version" },
        { BranchRole, "branch" },
        { ArchRole, "arch" },
        { InstalledRole, "installed" },
        { StateRole, "state" },
        { PermissionsRole, "permissions" },
    };
}

bool AppModel::matches(const FlatpakApp &app) const
{
    if (m_filter.isEmpty()) {
        return true;
    }
    const QString f = m_filter.toLower();
    return app.name.toLower().contains(f)
        || app.id.toLower().contains(f)
        || app.summary.toLower().contains(f);
}

void AppModel::rebuild()
{
    beginResetModel();
    m_visible.clear();
    for (int i = 0; i < m_all.size(); ++i) {
        if (matches(m_all.at(i))) {
            m_visible.append(i);
        }
    }
    endResetModel();
}

void AppModel::setApps(const QVector<FlatpakApp> &apps)
{
    m_all = apps;
    rebuild();
}

void AppModel::setFilter(const QString &filter)
{
    if (m_filter == filter) {
        return;
    }
    m_filter = filter;
    rebuild();
}

FlatpakApp *AppModel::find(const QString &id)
{
    for (FlatpakApp &app : m_all) {
        if (app.id == id) {
            return &app;
        }
    }
    return nullptr;
}

void AppModel::updateEntry(const QString &id)
{
    for (int i = 0; i < m_all.size(); ++i) {
        if (m_all.at(i).id == id) {
            const int row = m_visible.indexOf(i);
            if (row >= 0) {
                emit dataChanged(index(row), index(row));
            }
            return;
        }
    }
}

// ------------------------------------------------------- SoftwareCenterBackend

SoftwareCenterBackend::SoftwareCenterBackend(QObject *parent)
    : QObject(parent)
{
    loadConfig();
    QTimer::singleShot(0, this, &SoftwareCenterBackend::refreshRemote);
    QTimer::singleShot(0, this, &SoftwareCenterBackend::refreshInstalled);
}

QString SoftwareCenterBackend::configDir()
{
    return QDir::homePath() + QStringLiteral("/.config/ix1");
}

void SoftwareCenterBackend::loadConfig()
{
    QSettings settings(configDir() + QStringLiteral("/settings.conf"), QSettings::IniFormat);
    m_theme = settings.value(QStringLiteral("theme"), QStringLiteral("graphite")).toString();
}

void SoftwareCenterBackend::saveConfig() const
{
    QDir().mkpath(configDir());
    QSettings settings(configDir() + QStringLiteral("/settings.conf"), QSettings::IniFormat);
    settings.setValue(QStringLiteral("theme"), m_theme);
}

void SoftwareCenterBackend::setTheme(const QString &theme)
{
    if (m_theme == theme) {
        return;
    }
    m_theme = theme;
    saveConfig();
    emit themeChanged();
}

void SoftwareCenterBackend::setStatus(const QString &text)
{
    if (m_statusText == text) {
        return;
    }
    m_statusText = text;
    emit statusTextChanged();
}

void SoftwareCenterBackend::setFilter(const QString &filter)
{
    m_filter = filter;
    m_remoteModel.setFilter(filter);
    m_installedModel.setFilter(filter);
}

void SoftwareCenterBackend::refreshRemote()
{
    runProcess({ QStringLiteral("remote-ls"), QStringLiteral("--user"), QStringLiteral("--app"),
                 QStringLiteral("--columns=application,name,description,version,branch,arch"),
                 QStringLiteral("flathub") }, 1, QString());
}

void SoftwareCenterBackend::refreshInstalled()
{
    runProcess({ QStringLiteral("list"), QStringLiteral("--user"), QStringLiteral("--app"),
                 QStringLiteral("--columns=application,name,description,version,branch,arch") }, 2, QString());
}

void SoftwareCenterBackend::installApp(const QString &id)
{
    runProcess({ QStringLiteral("install"), QStringLiteral("--user"), QStringLiteral("-y"),
                 QStringLiteral("flathub"), id }, 3, id);
}

void SoftwareCenterBackend::removeApp(const QString &id)
{
    runProcess({ QStringLiteral("uninstall"), QStringLiteral("--user"), QStringLiteral("-y"), id }, 4, id);
}

void SoftwareCenterBackend::updateApp(const QString &id)
{
    runProcess({ QStringLiteral("update"), QStringLiteral("--user"), QStringLiteral("-y"), id }, 5, id);
}

void SoftwareCenterBackend::updateAll()
{
    runProcess({ QStringLiteral("update"), QStringLiteral("--user"), QStringLiteral("-y") }, 6, QString());
}

void SoftwareCenterBackend::launchApp(const QString &id)
{
    QProcess::startDetached(QStringLiteral("flatpak"), { QStringLiteral("run"), id });
}

QVariantMap SoftwareCenterBackend::appDetails(const QString &id) const
{
    QVariantMap details;
    details.insert(QStringLiteral("id"), id);

    // Find the entry in either model.
    FlatpakApp *app = const_cast<AppModel *>(&m_remoteModel)->find(id);
    if (!app) {
        app = const_cast<AppModel *>(&m_installedModel)->find(id);
    }
    if (app) {
        details.insert(QStringLiteral("name"), app->name);
        details.insert(QStringLiteral("summary"), app->summary);
        details.insert(QStringLiteral("version"), app->version);
        details.insert(QStringLiteral("branch"), app->branch);
        details.insert(QStringLiteral("arch"), app->arch);
        details.insert(QStringLiteral("installed"), app->installed);
        details.insert(QStringLiteral("state"), app->state);
    }

    // Permissions: installed apps via `flatpak info`, remote apps via
    // `flatpak remote-info --show-permissions`.
    QStringList args;
    if (details.value(QStringLiteral("installed")).toBool()) {
        args = { QStringLiteral("info"), QStringLiteral("--user"), QStringLiteral("--show-permissions"), id };
    } else {
        args = { QStringLiteral("remote-info"), QStringLiteral("--user"), QStringLiteral("--show-permissions"),
                 QStringLiteral("flathub"), id };
    }
    QProcess p;
    p.start(QStringLiteral("flatpak"), args);
    if (p.waitForFinished(5000)) {
        const QString out = QString::fromLocal8Bit(p.readAllStandardOutput()).trimmed();
        if (p.exitCode() == 0 && !out.isEmpty()) {
            details.insert(QStringLiteral("permissions"), out);
        } else {
            details.insert(QStringLiteral("permissions"), QStringLiteral("Available after install."));
        }
    } else {
        details.insert(QStringLiteral("permissions"), QStringLiteral("Available after install."));
    }
    return details;
}

void SoftwareCenterBackend::runProcess(const QStringList &args, int op, const QString &id)
{
    m_queue.append({ args, op, id });
    if (!m_running) {
        startNext();
    }
}

void SoftwareCenterBackend::startNext()
{
    if (m_queue.isEmpty() || m_running) {
        return;
    }
    const PendingOp op = m_queue.takeFirst();
    startProcess(op.args, op.op, op.id);
}

void SoftwareCenterBackend::startProcess(const QStringList &args, int op, const QString &id)
{
    if (op == 1) {
        m_remoteLoading = true;
        emit remoteLoadingChanged();
    } else if (op == 2) {
        m_installedLoading = true;
        emit installedLoadingChanged();
    } else {
        if (FlatpakApp *app = m_remoteModel.find(id)) {
            app->state = 1;
            m_remoteModel.updateEntry(id);
        }
        if (FlatpakApp *app = m_installedModel.find(id)) {
            app->state = 1;
            m_installedModel.updateEntry(id);
        }
        setStatus(op == 3 ? QStringLiteral("Installing %1…").arg(id)
                 : op == 4 ? QStringLiteral("Removing %1…").arg(id)
                 : op == 6 ? QStringLiteral("Updating applications…")
                           : QStringLiteral("Updating %1…").arg(id));
    }

    m_op = op;
    m_opId = id;
    m_stdout.clear();
    m_running = true;
    if (!m_proc) {
        m_proc = new QProcess(this);
        // Accumulate stdout incrementally: `flatpak remote-ls` output is larger
        // than the pipe buffer, so reading only after exit would deadlock.
        connect(m_proc, &QProcess::readyReadStandardOutput, this, [this]() {
            m_stdout += m_proc->readAllStandardOutput();
        });
        connect(m_proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, [this](int exitCode, QProcess::ExitStatus) {
            Q_UNUSED(exitCode)
            const QByteArray out = m_stdout;
            const int op = m_op;
            const QString id = m_opId;
            const bool ok = m_proc->exitStatus() == QProcess::NormalExit && m_proc->exitCode() == 0;
            if (op == 1 || op == 2) {
                parseListOutput(QString::fromLocal8Bit(out), op == 1);
            } else {
                applyOpResult(ok, id, op == 3 ? QStringLiteral("install")
                                 : op == 4 ? QStringLiteral("remove")
                                 : QStringLiteral("update"));
            }
            if (op == 1) {
                m_remoteLoading = false;
                emit remoteLoadingChanged();
            } else if (op == 2) {
                m_installedLoading = false;
                emit installedLoadingChanged();
            }
            m_running = false;
            emit operationFinished();
            startNext();
        });
    }
    m_proc->start(QStringLiteral("flatpak"), args);
}

void SoftwareCenterBackend::parseListOutput(const QString &out, bool remote)
{
    QVector<FlatpakApp> apps;
    if (!remote) {
        m_installedById.clear();
    }
    const QStringList lines = out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        const QStringList cols = splitTabs(line);
        if (cols.size() < 5) {
            continue;
        }
        FlatpakApp app;
        app.id = cols.value(0).trimmed();
        app.name = cols.value(1).trimmed();
        app.summary = cols.value(2).trimmed();
        app.version = cols.value(3).trimmed();
        app.branch = cols.value(4).trimmed();
        app.arch = cols.value(5).trimmed();
        app.installed = !remote;
        if (remote) {
            // Merge installed state.
            if (m_installedById.contains(app.id)) {
                app.installed = true;
            }
            apps.append(app);
        } else {
            apps.append(app);
            m_installedById.insert(app.id, app);
        }
    }

    if (remote) {
        // Preserve operation state across refreshes.
        for (FlatpakApp &app : apps) {
            if (FlatpakApp *old = m_remoteModel.find(app.id)) {
                app.state = old->state;
                app.permissions = old->permissions;
            }
        }
        m_remote = apps;
        // Mark installed entries in the installed model from the new remote list too.
        m_remoteModel.setApps(m_remote);
    } else {
        m_installed = apps;
        m_installedModel.setApps(m_installed);
        // Re-mark remote entries from the fresh installed list.
        for (FlatpakApp &app : m_remote) {
            app.installed = m_installedById.contains(app.id);
        }
        m_remoteModel.setApps(m_remote);
    }

    if (remote) {
        setStatus(QStringLiteral("%1 applications found on Flathub.").arg(m_remote.size()));
    } else {
        setStatus(QStringLiteral("%1 applications installed.").arg(m_installed.size()));
    }
}

void SoftwareCenterBackend::applyOpResult(bool ok, const QString &id, const QString &verb)
{
    if (FlatpakApp *app = m_remoteModel.find(id)) {
        app->state = ok ? 0 : 2;
        m_remoteModel.updateEntry(id);
    }
    if (FlatpakApp *app = m_installedModel.find(id)) {
        app->state = ok ? 0 : 2;
        m_installedModel.updateEntry(id);
    }
    setStatus(ok ? QStringLiteral("%1 %2 finished.").arg(verb, id)
                  : QStringLiteral("%1 %2 failed.").arg(verb, id));
    // Refresh both lists so install/remove state stays accurate.
    refreshRemote();
    refreshInstalled();
}
