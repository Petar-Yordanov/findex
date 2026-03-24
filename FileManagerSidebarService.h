#pragma once

#include <QObject>
#include <QVariantList>
#include <QStorageInfo>
#include <QTimer>
#include <QHash>
#include <QFutureWatcher>

class FileManagerSidebarService final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList drives READ drives NOTIFY drivesChanged)
    Q_PROPERTY(QVariantList sidebarTree READ sidebarTree CONSTANT)

public:
    explicit FileManagerSidebarService(QObject* parent = nullptr);

    QVariantList drives() const;
    QVariantList sidebarTree() const;

signals:
    void drivesChanged();

private:
    struct DriveSnapshot {
        QString rootPath;
        QString displayName;
        QString name;
        QString fileSystemType;
        qint64 bytesTotal = 0;
        qint64 bytesAvailable = 0;

        bool operator==(const DriveSnapshot& other) const
        {
            return rootPath == other.rootPath &&
                   displayName == other.displayName &&
                   name == other.name &&
                   fileSystemType == other.fileSystemType &&
                   bytesTotal == other.bytesTotal &&
                   bytesAvailable == other.bytesAvailable;
        }

        bool operator!=(const DriveSnapshot& other) const
        {
            return !(*this == other);
        }
    };

    struct ScanResult {
        QVariantList drives;
        QHash<QString, DriveSnapshot> snapshot;
    };

    void startDriveScan();
    static ScanResult scanDrives();
    QString formatDriveLabel(const QStorageInfo& storage) const;
    static QString formatStorageAmount(qint64 bytes);

private:
    QVariantList m_drives;
    QVariantList m_sidebarTree;
    QHash<QString, DriveSnapshot> m_lastSnapshot;
    QTimer m_drivePollTimer;
    QFutureWatcher<ScanResult> m_scanWatcher;
};