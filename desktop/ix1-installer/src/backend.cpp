#include "backend.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSettings>

// The installer runs as root in the live environment.

static QStringList deploymentsAt(const QString &sysroot)
{
    // <sysroot>/ostree/deploy/<stateroot>/deploy/<id>.<serial>/
    QStringList out;
    const QDir deployRoot(sysroot + QStringLiteral("/ostree/deploy"));
    for (const QString &st : deployRoot.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const QDir d(deployRoot.filePath(st + QStringLiteral("/deploy")));
        for (const QString &e : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
            out << d.filePath(e);
    }
    return out;
}

// vda -> vda3 ; nvme0n1 -> nvme0n1p3
static QString part(const QString &disk, int n)
{
    const bool needsP = disk.at(disk.size() - 1).isDigit();
    return disk + (needsP ? QStringLiteral("p") : QString()) + QString::number(n);
}

Backend::Backend(QObject *parent) : QObject(parent)
{
    // Install image refs: /etc/ix1-install.conf written by the
    // Containerfile, overridable via env for development.
    QSettings conf(QStringLiteral("/etc/ix1-install.conf"), QSettings::IniFormat);
    m_sourceImgref = qEnvironmentVariable(
        "IX1_INSTALL_SOURCE",
        conf.value(QStringLiteral("install/source"), QStringLiteral("oci:/usr/share/ix1/os"))
            .toString().toUtf8());
    m_targetImgref = qEnvironmentVariable(
        "IX1_INSTALL_TARGET",
        conf.value(QStringLiteral("install/target"), QStringLiteral("10.0.2.2:5000/ix1-os:dev"))
            .toString().toUtf8());
    enumerateDisks();
}

// True when the device or any descendant holds a live-boot mount.
static bool hasBootMount(const QJsonObject &d)
{
    const QJsonArray mounts = d.value(QStringLiteral("mountpoints")).toArray();
    for (const auto &m : mounts) {
        const QString mp = m.toString();
        if (mp == QLatin1String("/") || mp.startsWith(QLatin1String("/run/initramfs")) ||
            mp.startsWith(QLatin1String("/sysroot")))
            return true;
    }
    const QJsonArray children = d.value(QStringLiteral("children")).toArray();
    for (const auto &c : children)
        if (hasBootMount(c.toObject()))
            return true;
    return false;
}

void Backend::enumerateDisks()
{
    m_disks.clear();
    m_selectedDisk = -1;

    // Render/smoke checks run where no real block device exists;
    // IX1_DEMO=1 seeds representative rows so every screen can be captured.
    if (qEnvironmentVariableIsSet("IX1_DEMO")) {
        QVariantMap a;
        a[QStringLiteral("name")] = QStringLiteral("/dev/vda");
        a[QStringLiteral("model")] = QStringLiteral("Virtio Block Device");
        a[QStringLiteral("size")] = 32LL << 30;
        a[QStringLiteral("sizeText")] = QStringLiteral("32 GB");
        a[QStringLiteral("tran")] = QStringLiteral("virtio");
        a[QStringLiteral("removable")] = false;
        a[QStringLiteral("parts")] = 0;
        a[QStringLiteral("installable")] = true;
        QVariantMap b;
        b[QStringLiteral("name")] = QStringLiteral("/dev/nvme0n1");
        b[QStringLiteral("model")] = QStringLiteral("Samsung PM9A1 NVMe");
        b[QStringLiteral("size")] = 512LL << 30;
        b[QStringLiteral("sizeText")] = QStringLiteral("512 GB");
        b[QStringLiteral("tran")] = QStringLiteral("nvme");
        b[QStringLiteral("removable")] = false;
        b[QStringLiteral("parts")] = 3;
        b[QStringLiteral("installable")] = true;
        QVariantMap c;
        c[QStringLiteral("name")] = QStringLiteral("/dev/sda");
        c[QStringLiteral("model")] = QStringLiteral("ix1 live USB");
        c[QStringLiteral("size")] = 16LL << 30;
        c[QStringLiteral("sizeText")] = QStringLiteral("16 GB");
        c[QStringLiteral("tran")] = QStringLiteral("usb");
        c[QStringLiteral("removable")] = true;
        c[QStringLiteral("parts")] = 2;
        c[QStringLiteral("installable")] = false;
        c[QStringLiteral("note")] = QStringLiteral("installation media — unavailable");
        m_disks = {a, b, c};
        m_selectedDisk = 0;
        emit disksChanged();
        emit selectedDiskChanged();
        return;
    }

    QProcess p;
    p.start(QStringLiteral("lsblk"),
            {QStringLiteral("-J"), QStringLiteral("-b"),
             QStringLiteral("-o"), QStringLiteral("NAME,SIZE,TYPE,MODEL,TRAN,RM,MOUNTPOINTS")});
    if (!p.waitForFinished(10000))
        return;

    const QJsonArray list =
        QJsonDocument::fromJson(p.readAllStandardOutput())
            .object().value(QStringLiteral("blockdevices")).toArray();

    for (const auto &v : list) {
        const QJsonObject d = v.toObject();
        if (d.value(QStringLiteral("type")).toString() != QLatin1String("disk"))
            continue;

        const QString name = d.value(QStringLiteral("name")).toString();
        const qint64 size = d.value(QStringLiteral("size")).toVariant().toLongLong();
        QString model = d.value(QStringLiteral("model")).toString().trimmed();
        if (model.isEmpty())
            model = name.startsWith(QLatin1String("vd")) ? QStringLiteral("Virtio Block Device")
                                                       : name;
        QString tran = d.value(QStringLiteral("tran")).toString();
        if (tran.isEmpty()) {
            if (name.startsWith(QLatin1String("vd")))
                tran = QStringLiteral("virtio");
            else if (name.startsWith(QLatin1String("nvme")))
                tran = QStringLiteral("nvme");
            else if (name.startsWith(QLatin1String("mmcblk")))
                tran = QStringLiteral("mmc");
            else if (name.startsWith(QLatin1String("sr")))
                tran = QStringLiteral("optical");
        }
        int parts = 0;
        const QJsonArray children = d.value(QStringLiteral("children")).toArray();
        for (const auto &c : children)
            if (c.toObject().value(QStringLiteral("type")).toString() == QLatin1String("part"))
                ++parts;

        QVariantMap row;
        row[QStringLiteral("name")] = QStringLiteral("/dev/") + name;
        row[QStringLiteral("model")] = model;
        row[QStringLiteral("size")] = size;
        row[QStringLiteral("sizeText")] =
            size >= (1LL << 30)
                ? QString::number(size / double(1LL << 30), 'f',
                                  size % (1LL << 30) ? 1 : 0) + QStringLiteral(" GB")
                : QString::number(size / (1 << 20)) + QStringLiteral(" MB");
        row[QStringLiteral("tran")] = tran;
        row[QStringLiteral("removable")] = d.value(QStringLiteral("rm")).toBool();
        row[QStringLiteral("parts")] = parts;
        if (hasBootMount(d)) {
            row[QStringLiteral("installable")] = false;
            row[QStringLiteral("note")] = QStringLiteral("installation media — unavailable");
        } else if (size < (8LL << 30)) {
            row[QStringLiteral("installable")] = false;
            row[QStringLiteral("note")] = QStringLiteral("needs ≥ 8 GB");
        } else {
            row[QStringLiteral("installable")] = true;
        }
        m_disks.append(row);
    }
    // First installable disk is the default target.
    for (int i = 0; i < m_disks.size(); ++i)
        if (m_disks[i].toMap().value(QStringLiteral("installable")).toBool()) {
            m_selectedDisk = i;
            break;
        }
    emit disksChanged();
    emit selectedDiskChanged();
}

void Backend::refreshDisks() { enumerateDisks(); }

void Backend::setSelectedDisk(int i)
{
    if (m_selectedDisk == i)
        return;
    if (i < 0 || i >= m_disks.size() ||
        !m_disks[i].toMap().value(QStringLiteral("installable")).toBool())
        return;
    m_selectedDisk = i;
    emit selectedDiskChanged();
}

void Backend::setEncrypt(bool v)
{
    if (m_encrypt == v)
        return;
    m_encrypt = v;
    emit encryptChanged();
}

void Backend::setProgress(int pct, const QString &text)
{
    if (pct != m_progress) {
        m_progress = pct;
        emit progressChanged();
    }
    if (text != m_progressText) {
        m_progressText = text;
        emit progressTextChanged();
    }
}

void Backend::appendLog(const QString &line, bool active)
{
    if (!m_logLines.isEmpty() && m_logLines.last().startsWith(QLatin1String("→")))
        m_logLines.last() = QStringLiteral("✓ ") + m_logLines.last().mid(2);
    m_logLines.append((active ? QStringLiteral("→ ") : QStringLiteral("✓ ")) + line);
    emit logLinesChanged();
}

void Backend::fail(const QString &msg)
{
    appendLog(QStringLiteral("failed: ") + msg, false);
    m_logLines.last() = QStringLiteral("✗ ") + m_logLines.last().mid(2);
    m_error = msg;
    emit errorChanged();
    m_installing = false;
    emit installingChanged();
    setProgress(m_progress, QStringLiteral("Install failed — see log."));
}

bool Backend::runStep(const QString &desc, int pctBefore, const QString &cmd,
                      const QStringList &args, QString *out, const QString &stdinText)
{
    setProgress(pctBefore, desc);
    appendLog(desc, true);

    QProcess p;
    p.start(cmd, args);
    if (!stdinText.isNull()) {
        p.write(stdinText.toUtf8());
        p.closeWriteChannel();
    }
    if (!p.waitForStarted(5000) || !p.waitForFinished(-1)) {
        fail(cmd + QStringLiteral(" failed to run"));
        return false;
    }
    const QString output = QString::fromUtf8(p.readAllStandardOutput());
    const QString err = QString::fromUtf8(p.readAllStandardError());
    if (p.exitStatus() != QProcess::NormalExit || p.exitCode() != 0) {
        fail(desc + QStringLiteral(" — ") +
             (err.isEmpty() ? output : err).left(300).trimmed());
        return false;
    }
    if (out)
        *out = output;
    return true;
}

// bootc deploys the image but creates no user. The deployment's /etc is
// plain files under the sysroot, so useradd/chpasswd -R work directly.
bool Backend::provisionUser(const QString &sysroot)
{
    const QString deploy = deploymentsAt(sysroot).isEmpty()
        ? QString()
        : deploymentsAt(sysroot).first();
    if (deploy.isEmpty()) {
        fail(QStringLiteral("no deployment found under ") + sysroot);
        return false;
    }
    if (!runStep(QStringLiteral("creating account"), 94, QStringLiteral("useradd"),
                 {QStringLiteral("-R"), deploy,
                  QStringLiteral("-s"), QStringLiteral("/bin/bash"),
                  QStringLiteral("-G"), QStringLiteral("wheel"), m_userName}))
        return false;

    // The deployment's /home is not the live home dir — at boot /home comes
    // from the stateroot. Create the home via tmpfiles (same mechanism as
    // distribution/bootc/files/usr/lib/tmpfiles.d/ix1-home.conf) so it
    // exists with the right owner and SELinux label on first boot.
    {
        QFile f(deploy + QStringLiteral("/usr/lib/tmpfiles.d/ix1-install-user.conf"));
        if (f.open(QIODevice::WriteOnly | QIODevice::Text))
            f.write(QByteArray("d /home/") + m_userName.toUtf8() +
                    QByteArray(" 0700 ") + m_userName.toUtf8() +
                    QByteArray(" ") + m_userName.toUtf8() + QByteArray(" -\n"));
    }
    if (!runStep(QStringLiteral("setting password"), 96, QStringLiteral("chpasswd"),
                 {QStringLiteral("-R"), deploy}, nullptr,
                 m_userName + QLatin1Char(':') + m_password + QLatin1Char('\n')))
        return false;
    if (!m_fullName.isEmpty())
        runStep(QStringLiteral("setting full name"), 96, QStringLiteral("usermod"),
                {QStringLiteral("-R"), deploy, QStringLiteral("-c"), m_fullName, m_userName});
    return true;
}

void Backend::startInstall()
{
    if (m_installing || m_selectedDisk < 0 || m_selectedDisk >= m_disks.size())
        return;

    m_error.clear();
    emit errorChanged();
    m_done = false;
    emit doneChanged();
    m_logLines.clear();
    emit logLinesChanged();
    m_installing = true;
    emit installingChanged();

    const QString disk = m_disks[m_selectedDisk].toMap()
                             .value(QStringLiteral("name")).toString();
    const QString sysroot = QStringLiteral("/mnt/ix1-target");

    if (!m_encrypt) {
        // bootc partitions (ESP + boot + root) and deploys itself.
        if (!runStep(QStringLiteral("deploying image"), 10, QStringLiteral("bootc"),
                     {QStringLiteral("install"), QStringLiteral("to-disk"), disk,
                      QStringLiteral("--source-imgref"), m_sourceImgref,
                      QStringLiteral("--target-imgref"), m_targetImgref,
                      QStringLiteral("--wipe")}))
            return;

        // bootc to-disk layout: p1 ESP, p2 boot, p3 root.
        QDir().mkpath(sysroot);
        if (!runStep(QStringLiteral("mounting deployment"), 90, QStringLiteral("mount"),
                     {part(disk, 3), sysroot}))
            return;
        if (!provisionUser(sysroot))
            return;
        runStep(QStringLiteral("unmounting"), 98, QStringLiteral("umount"), {sysroot});
    } else {
        // Manual layout: p1 ESP (512M), p2 /boot (1G ext4), p3 LUKS -> ext4.
        // /boot must stay outside LUKS: GRUB cannot read a kernel/initramfs
        // from a LUKS2 (argon2) volume, so decryption only starts with the
        // initramfs via rd.luks.name below.
        const QString esp = part(disk, 1);
        const QString bootPart = part(disk, 2);
        const QString luksPart = part(disk, 3);

        if (!runStep(QStringLiteral("wiping disk"), 6, QStringLiteral("sfdisk"),
                     {disk}, nullptr,
                     QStringLiteral("label: gpt\nsize=512M,type=U\nsize=1G,type=L\ntype=L\n")))
            return;
        if (!runStep(QStringLiteral("settling devices"), 8, QStringLiteral("udevadm"),
                     {QStringLiteral("settle")}))
            return;
        if (!runStep(QStringLiteral("encrypting disk"), 12, QStringLiteral("cryptsetup"),
                     {QStringLiteral("luksFormat"), QStringLiteral("--type"),
                      QStringLiteral("luks2"), QStringLiteral("--batch-mode"), luksPart},
                     nullptr, m_luksPass + QLatin1Char('\n')))
            return;
        if (!runStep(QStringLiteral("opening container"), 14, QStringLiteral("cryptsetup"),
                     {QStringLiteral("open"), luksPart, QStringLiteral("ix1root")},
                     nullptr, m_luksPass + QLatin1Char('\n')))
            return;
        if (!runStep(QStringLiteral("formatting esp"), 16, QStringLiteral("mkfs.vfat"),
                     {QStringLiteral("-F32"), esp}))
            return;
        if (!runStep(QStringLiteral("formatting boot"), 17, QStringLiteral("mkfs.ext4"),
                     {QStringLiteral("-F"), bootPart}))
            return;
        if (!runStep(QStringLiteral("formatting root"), 18, QStringLiteral("mkfs.ext4"),
                     {QStringLiteral("-F"), QStringLiteral("/dev/mapper/ix1root")}))
            return;

        // Mount the fresh root first — its fs is empty, so the /boot and
        // /boot/efi mount points must be created inside it before mounting.
        QDir().mkpath(sysroot);
        if (!runStep(QStringLiteral("mounting target"), 20, QStringLiteral("mount"),
                     {QStringLiteral("/dev/mapper/ix1root"), sysroot}))
            return;
        QDir().mkpath(sysroot + QStringLiteral("/boot/efi"));
        if (!runStep(QStringLiteral("mounting boot"), 21, QStringLiteral("mount"),
                     {bootPart, sysroot + QStringLiteral("/boot")}))
            return;
        if (!runStep(QStringLiteral("mounting esp"), 22, QStringLiteral("mount"),
                     {esp, sysroot + QStringLiteral("/boot/efi")}))
            return;

        QString uuid;
        if (!runStep(QStringLiteral("reading luks uuid"), 24, QStringLiteral("blkid"),
                     {QStringLiteral("-s"), QStringLiteral("UUID"), QStringLiteral("-o"),
                      QStringLiteral("value"), luksPart}, &uuid))
            return;
        uuid = uuid.trimmed();

        if (!runStep(QStringLiteral("deploying image"), 30, QStringLiteral("bootc"),
                     {QStringLiteral("install"), QStringLiteral("to-filesystem"),
                      QStringLiteral("--source-imgref"), m_sourceImgref,
                      QStringLiteral("--target-imgref"), m_targetImgref,
                      QStringLiteral("--karg"),
                      QStringLiteral("rd.luks.name=") + uuid + QStringLiteral("=ix1root"),
                      sysroot}))
            return;

        // Tell the installed system how to open the container.
        for (const QString &deploy : deploymentsAt(sysroot)) {
            QFile f(deploy + QStringLiteral("/etc/crypttab"));
            if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
                f.write(QByteArray("ix1root UUID=") + uuid.toUtf8() +
                        QByteArray(" none luks,discard\n"));
            }
        }

        if (!provisionUser(sysroot))
            return;
        runStep(QStringLiteral("unmounting"), 98, QStringLiteral("umount"),
                {QStringLiteral("-R"), sysroot});
        runStep(QStringLiteral("closing luks"), 98, QStringLiteral("cryptsetup"),
                {QStringLiteral("close"), QStringLiteral("ix1root")});
    }

    setProgress(100, QStringLiteral("ix1 installed."));
    appendLog(QStringLiteral("installation complete"), false);
    m_installing = false;
    emit installingChanged();
    m_done = true;
    emit doneChanged();
}

void Backend::reboot()
{
    QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("reboot")});
}
