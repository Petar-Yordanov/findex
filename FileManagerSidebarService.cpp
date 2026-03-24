#include "FileManagerSidebarService.h"

#include <QVariantMap>
#include <QString>
#include <QStringList>

FileManagerSidebarService::FileManagerSidebarService(QObject* parent)
    : QObject(parent)
{
    reloadDrives();
    m_lastSnapshot = captureDriveSnapshot();

    connect(&m_drivePollTimer, &QTimer::timeout, this, [this]() {
        const auto currentSnapshot = captureDriveSnapshot();
        if (currentSnapshot != m_lastSnapshot) {
            m_lastSnapshot = currentSnapshot;
            reloadDrives();
            emit drivesChanged();
        }
    });

    m_drivePollTimer.start(3000);

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
}

QHash<QString, FileManagerSidebarService::DriveSnapshot> FileManagerSidebarService::captureDriveSnapshot() const
{
    QHash<QString, DriveSnapshot> snapshot;

    for (const QStorageInfo& storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady())
            continue;

        const qint64 total = storage.bytesTotal();
        if (total <= 0)
            continue;

        DriveSnapshot item;
        item.rootPath = storage.rootPath();
        item.displayName = storage.displayName().trimmed();
        item.name = storage.name().trimmed();
        item.fileSystemType = QString::fromUtf8(storage.fileSystemType()).trimmed();
        item.bytesTotal = storage.bytesTotal();
        item.bytesAvailable = storage.bytesAvailable();

        snapshot.insert(item.rootPath, item);
    }

    return snapshot;
}

void FileManagerSidebarService::reloadDrives()
{
    QVariantList drives;

    for (const QStorageInfo& storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady())
            continue;

        const qint64 total = storage.bytesTotal();
        const qint64 free = storage.bytesAvailable();
        const qint64 used = total - free;

        if (total <= 0)
            continue;

        QVariantMap drive;
        drive["label"] = formatDriveLabel(storage);
        drive["icon"] = storage.isReadOnly() ? "lock" : "hard-drive";
        drive["used"] = double(used) / double(total);
        drive["total"] = 1.0;
        drive["usedText"] = QString("%1 free of %2")
                                .arg(formatStorageAmount(free))
                                .arg(formatStorageAmount(total));

        drives.append(drive);
    }

    m_drives = drives;
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

QString FileManagerSidebarService::formatStorageAmount(qint64 bytes) const
{
    const double gb = bytes / 1024.0 / 1024.0 / 1024.0;
    if (gb < 1024.0)
        return QString("%1 GB").arg(gb, 0, 'f', 1);

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