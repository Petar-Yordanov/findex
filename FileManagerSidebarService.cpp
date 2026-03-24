#include "FileManagerSidebarService.h"

#include <QVariantMap>
#include <QStringList>
#include <QtConcurrent/QtConcurrentRun>

FileManagerSidebarService::FileManagerSidebarService(QObject* parent)
    : QObject(parent)
{
    m_sidebarTree = {
        QVariantMap{
            {"label", "Quick Access"},
            {"icon", ""},
            {"section", true},
            {"kind", "section"},
            {"rows", QVariantList{
                         QVariantMap{{"label", "Recent"},    {"icon", "history"},          {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Home"},      {"icon", "home"},             {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Desktop"},   {"icon", "desktop-windows"},  {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Downloads"}, {"icon", "download"},         {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Documents"}, {"icon", "description"},      {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Pictures"},  {"icon", "image"},            {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Music"},     {"icon", "music-note"},       {"kind", "quick"}, {"section", false}},
                         QVariantMap{{"label", "Videos"},    {"icon", "movie"},            {"kind", "quick"}, {"section", false}}
                     }}
        }
    };

    connect(&m_scanWatcher, &QFutureWatcher<ScanResult>::finished, this, [this]() {
        const ScanResult result = m_scanWatcher.result();

        if (result.snapshot != m_lastSnapshot) {
            m_lastSnapshot = result.snapshot;
            m_drives = result.drives;
            emit drivesChanged();
        }
    });

    connect(&m_drivePollTimer, &QTimer::timeout, this, [this]() {
        startDriveScan();
    });

    m_drivePollTimer.start(5000); // a bit less aggressive
    startDriveScan();             // initial load
}

void FileManagerSidebarService::startDriveScan()
{
    if (m_scanWatcher.isRunning())
        return;

    m_scanWatcher.setFuture(QtConcurrent::run(&FileManagerSidebarService::scanDrives));
}

FileManagerSidebarService::ScanResult FileManagerSidebarService::scanDrives()
{
    ScanResult result;

    for (const QStorageInfo& storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady())
            continue;

        const qint64 total = storage.bytesTotal();
        const qint64 free = storage.bytesAvailable();

        if (total <= 0)
            continue;

        const qint64 used = total - free;

        DriveSnapshot item;
        item.rootPath = storage.rootPath();
        item.displayName = storage.displayName().trimmed();
        item.name = storage.name().trimmed();
        item.fileSystemType = QString::fromUtf8(storage.fileSystemType()).trimmed();
        item.bytesTotal = total;
        item.bytesAvailable = free;
        result.snapshot.insert(item.rootPath, item);

        QString root = storage.rootPath();
        QString driveId = root;
        driveId.remove('/');

        QString displayName = storage.displayName().trimmed();
        QString fsType = QString::fromUtf8(storage.fileSystemType()).trimmed();

        QString baseLabel;
        if (displayName.isEmpty() || displayName == root || displayName == driveId)
            baseLabel = driveId;
        else
            baseLabel = QString("%1 (%2)").arg(displayName, driveId);

        QVariantMap drive;
        drive["label"] = fsType.isEmpty() ? baseLabel
                                          : QString("%1 [%2]").arg(baseLabel, fsType);
        drive["icon"] = storage.isReadOnly() ? "lock" : "hard-drive";
        drive["used"] = double(used) / double(total);
        drive["total"] = 1.0;
        drive["usedText"] = QString("%1 free of %2")
                                .arg(formatStorageAmount(free))
                                .arg(formatStorageAmount(total));

        result.drives.append(drive);
    }

    return result;
}

QString FileManagerSidebarService::formatDriveLabel(const QStorageInfo& storage) const
{
    QString root = storage.rootPath();
    QString driveId = root;
    driveId.remove('/');

    QString displayName = storage.displayName().trimmed();
    QString fsType = QString::fromUtf8(storage.fileSystemType()).trimmed();

    QString baseLabel;
    if (displayName.isEmpty() || displayName == root || displayName == driveId)
        baseLabel = driveId;
    else
        baseLabel = QString("%1 (%2)").arg(displayName, driveId);

    if (fsType.isEmpty())
        return baseLabel;

    return QString("%1 [%2]").arg(baseLabel, fsType);
}

QString FileManagerSidebarService::formatStorageAmount(qint64 bytes)
{
    const double gb = bytes / 1024.0 / 1024.0 / 1024.0;
    if (gb < 1024.0)
        return QString("%1 GB").arg(gb, 0, 'f', 0);

    const double tb = gb / 1024.0;
    return QString("%1 TB").arg(tb, 0, 'f', 2);
}

QVariantList FileManagerSidebarService::drives() const
{
    return m_drives;
}

QVariantList FileManagerSidebarService::sidebarTree() const
{
    return m_sidebarTree;
}