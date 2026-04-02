#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

class DriveListModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    struct DriveItem
    {
        QString label;
        QString path;
        QString icon;
        qint64 used = 0;
        qint64 total = 0;
        QString usedText;
    };

    enum Roles
    {
        LabelRole = Qt::UserRole + 1,
        PathRole,
        IconRole,
        UsedRole,
        TotalRole,
        UsedTextRole
    };
    Q_ENUM(Roles)

    explicit DriveListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void loadDefaults();
    void setDrives(const QVector<DriveItem>& items);

private:
    QVector<DriveItem> m_items;
};