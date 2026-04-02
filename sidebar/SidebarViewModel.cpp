#include "SidebarViewModel.h"

#include <QDir>
#include <QStorageInfo>
#include <QtConcurrent>

#include "SidebarTreeModel.h"
#include "DriveListModel.h"

SidebarViewModel::SidebarViewModel(QObject* parent)
    : QObject(parent)
    , m_treeModel(new SidebarTreeModel(this))
    , m_drivesModel(new DriveListModel(this))
{
    connect(&m_driveWatcher, &QFutureWatcher<QVector<DriveListModel::DriveItem>>::finished, this, [this]() {
        m_drivesModel->setDrives(m_driveWatcher.result());
    });

    connect(&m_driveRefreshTimer, &QTimer::timeout, this, [this]() {
        startDriveRefresh();
    });

    m_driveRefreshTimer.setInterval(5000);
    m_driveRefreshTimer.start();

    startDriveRefresh();
}

QObject* SidebarViewModel::treeModel() const
{
    return m_treeModel;
}

QObject* SidebarViewModel::drivesModel() const
{
    return m_drivesModel;
}

QString SidebarViewModel::contextLabel() const
{
    return m_contextLabel;
}

QString SidebarViewModel::contextIcon() const
{
    return m_contextIcon;
}

QString SidebarViewModel::contextKind() const
{
    return m_contextKind;
}

QString SidebarViewModel::contextPath() const
{
    return m_contextPath;
}

QString SidebarViewModel::hoveredLabel() const
{
    return m_hoveredLabel;
}

QString SidebarViewModel::hoveredKind() const
{
    return m_hoveredKind;
}

void SidebarViewModel::openLocation(const QString& label, const QString& icon, const QString& kind, const QString& path)
{
    const bool selectionChangedNow =
        (m_selectedLabel != label) || (m_selectedKind != kind);

    m_selectedLabel = label;
    m_selectedKind = kind;

    if (selectionChangedNow)
        emit selectionChanged();

    emit openRequested(label, icon, kind, path);
    emit hoveredChanged();
}

void SidebarViewModel::setContextItem(const QString& label, const QString& icon, const QString& kind, const QString& path)
{
    if (m_contextLabel == label
        && m_contextIcon == icon
        && m_contextKind == kind
        && m_contextPath == path)
        return;

    m_contextLabel = label;
    m_contextIcon = icon;
    m_contextKind = kind;
    m_contextPath = path;
    emit contextChanged();
}

bool SidebarViewModel::isSelected(const QString& label, const QString& kind) const
{
    return m_selectedLabel == label && m_selectedKind == kind;
}

void SidebarViewModel::setHoveredItem(const QString& label, const QString& kind)
{
    if (m_hoveredLabel == label && m_hoveredKind == kind)
        return;

    m_hoveredLabel = label;
    m_hoveredKind = kind;
    emit hoveredChanged();
}

void SidebarViewModel::clearHoveredItem(const QString& label, const QString& kind)
{
    if (m_hoveredLabel != label || m_hoveredKind != kind)
        return;

    m_hoveredLabel.clear();
    m_hoveredKind.clear();
    emit hoveredChanged();
}

bool SidebarViewModel::isHovered(const QString& label, const QString& kind) const
{
    return m_hoveredLabel == label && m_hoveredKind == kind;
}

void SidebarViewModel::requestOpenContextInNewTab()
{
    if (m_contextLabel.isEmpty())
        return;

    emit openInNewTabRequested(m_contextLabel, m_contextIcon, m_contextKind, m_contextPath);
}

void SidebarViewModel::requestCopyContextPath()
{
    if (m_contextLabel.isEmpty())
        return;

    emit copyPathRequested(m_contextLabel, m_contextKind, m_contextPath);
}

void SidebarViewModel::requestPinContext()
{
    if (m_contextLabel.isEmpty())
        return;

    emit pinRequested(m_contextLabel, m_contextKind, m_contextPath);
}

void SidebarViewModel::requestContextProperties()
{
    if (m_contextLabel.isEmpty())
        return;

    emit propertiesRequested(m_contextLabel, m_contextKind, m_contextPath);
}

void SidebarViewModel::startDriveRefresh()
{
    if (m_driveWatcher.isRunning())
        return;

    m_driveWatcher.setFuture(QtConcurrent::run(&SidebarViewModel::queryDrives));
}

QVector<DriveListModel::DriveItem> SidebarViewModel::queryDrives()
{
    QVector<DriveListModel::DriveItem> result;

    const QList<QStorageInfo> volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo& storage : volumes)
    {
        if (!storage.isValid() || !storage.isReady())
            continue;

        const QString rootPath = QDir::fromNativeSeparators(storage.rootPath());
        if (rootPath.trimmed().isEmpty())
            continue;

        const qint64 total = storage.bytesTotal();
        const qint64 free = storage.bytesAvailable();
        const qint64 used = (total > 0 && free >= 0) ? (total - free) : 0;

        DriveListModel::DriveItem item;
        item.path = rootPath;
        item.label = driveLabelForPath(rootPath, storage.displayName());
        item.icon = iconForDrivePath(rootPath);
        item.used = qMax<qint64>(0, used);
        item.total = qMax<qint64>(0, total);
        item.usedText = formatCapacityText(item.used, item.total);

        result.push_back(item);
    }

    std::sort(result.begin(), result.end(), [](const auto& a, const auto& b) {
        return a.path.toLower() < b.path.toLower();
    });

    return result;
}

QString SidebarViewModel::formatCapacityText(qint64 usedBytes, qint64 totalBytes)
{
    auto format = [](qint64 bytes) -> QString {
        static const double kb = 1024.0;
        static const double mb = kb * 1024.0;
        static const double gb = mb * 1024.0;
        static const double tb = gb * 1024.0;

        const double value = static_cast<double>(bytes);

        if (value >= tb)
            return QString::number(value / tb, 'f', 2) + QStringLiteral(" TB");
        if (value >= gb)
            return QString::number(value / gb, 'f', 2) + QStringLiteral(" GB");
        if (value >= mb)
            return QString::number(value / mb, 'f', 1) + QStringLiteral(" MB");
        if (value >= kb)
            return QString::number(value / kb, 'f', 1) + QStringLiteral(" KB");
        return QString::number(bytes) + QStringLiteral(" B");
    };

    if (totalBytes <= 0)
        return QStringLiteral("Capacity unavailable");

    return QStringLiteral("%1 used of %2").arg(format(usedBytes), format(totalBytes));
}

QString SidebarViewModel::driveLabelForPath(const QString& rootPath, const QString& displayName)
{
#ifdef Q_OS_WINDOWS
    QString letter = rootPath;
    if (letter.endsWith('/'))
        letter.chop(1);

    const QString trimmedName = displayName.trimmed();

    if (!trimmedName.isEmpty()) {
        if (trimmedName.startsWith(letter, Qt::CaseInsensitive))
            return QStringLiteral("Local Disk (%1)").arg(letter);

        return QStringLiteral("%1 (%2)").arg(trimmedName, letter);
    }

    return QStringLiteral("Local Disk (%1)").arg(letter);
#else
    if (!displayName.trimmed().isEmpty())
        return QStringLiteral("%1 (%2)").arg(displayName.trimmed(), rootPath);

    return rootPath;
#endif
}

QString SidebarViewModel::iconForDrivePath(const QString& rootPath)
{
    const QString lower = rootPath.toLower();
    if (lower.contains(QStringLiteral("usb")))
        return QStringLiteral("usb");
    return QStringLiteral("hard-drive");
}