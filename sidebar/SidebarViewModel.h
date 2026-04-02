#pragma once

#include <QObject>
#include <QString>
#include <QFutureWatcher>
#include <QTimer>
#include <QVector>
#include "DriveListModel.h"

class SidebarTreeModel;

class SidebarViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QObject* treeModel READ treeModel CONSTANT)
    Q_PROPERTY(QObject* drivesModel READ drivesModel CONSTANT)

    Q_PROPERTY(QString contextLabel READ contextLabel NOTIFY contextChanged)
    Q_PROPERTY(QString contextIcon READ contextIcon NOTIFY contextChanged)
    Q_PROPERTY(QString contextKind READ contextKind NOTIFY contextChanged)
    Q_PROPERTY(QString contextPath READ contextPath NOTIFY contextChanged)

    Q_PROPERTY(QString hoveredLabel READ hoveredLabel NOTIFY hoveredChanged)
    Q_PROPERTY(QString hoveredKind READ hoveredKind NOTIFY hoveredChanged)

public:
    explicit SidebarViewModel(QObject* parent = nullptr);

    QObject* treeModel() const;
    QObject* drivesModel() const;

    QString contextLabel() const;
    QString contextIcon() const;
    QString contextKind() const;
    QString contextPath() const;

    QString hoveredLabel() const;
    QString hoveredKind() const;

    Q_INVOKABLE void openLocation(const QString& label, const QString& icon, const QString& kind, const QString& path);
    Q_INVOKABLE void setContextItem(const QString& label, const QString& icon, const QString& kind, const QString& path);

    Q_INVOKABLE bool isSelected(const QString& label, const QString& kind) const;

    Q_INVOKABLE void setHoveredItem(const QString& label, const QString& kind);
    Q_INVOKABLE void clearHoveredItem(const QString& label, const QString& kind);
    Q_INVOKABLE bool isHovered(const QString& label, const QString& kind) const;

    Q_INVOKABLE void requestOpenContextInNewTab();
    Q_INVOKABLE void requestCopyContextPath();
    Q_INVOKABLE void requestPinContext();
    Q_INVOKABLE void requestContextProperties();

signals:
    void contextChanged();
    void hoveredChanged();
    void selectionChanged();

    void openRequested(const QString& label, const QString& icon, const QString& kind, const QString& path);
    void openInNewTabRequested(const QString& label, const QString& icon, const QString& kind, const QString& path);
    void copyPathRequested(const QString& label, const QString& kind, const QString& path);
    void pinRequested(const QString& label, const QString& kind, const QString& path);
    void propertiesRequested(const QString& label, const QString& kind, const QString& path);

private:
    void startDriveRefresh();
    static QVector<DriveListModel::DriveItem> queryDrives();
    static QString formatCapacityText(qint64 usedBytes, qint64 totalBytes);
    static QString driveLabelForPath(const QString& rootPath, const QString& displayName);
    static QString iconForDrivePath(const QString& rootPath);

private:
    SidebarTreeModel* m_treeModel;
    DriveListModel* m_drivesModel;

    QString m_selectedLabel;
    QString m_selectedKind;

    QString m_contextLabel;
    QString m_contextIcon;
    QString m_contextKind;
    QString m_contextPath;

    QString m_hoveredLabel;
    QString m_hoveredKind;

    QTimer m_driveRefreshTimer;
    QFutureWatcher<QVector<DriveListModel::DriveItem>> m_driveWatcher;
};