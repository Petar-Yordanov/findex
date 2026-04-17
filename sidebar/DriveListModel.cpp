#include "DriveListModel.h"

DriveListModel::DriveListModel(QObject* parent)
    : QAbstractListModel(parent)
{
    loadDefaults();
}

int DriveListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_items.size();
}

QVariant DriveListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const auto& item = m_items.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
    case LabelRole:
        return item.label;
    case PathRole:
        return item.path;
    case IconRole:
        return item.icon;
    case UsedRole:
        return item.used;
    case TotalRole:
        return item.total;
    case UsedTextRole:
        return item.usedText;
    default:
        return {};
    }
}

QHash<int, QByteArray> DriveListModel::roleNames() const
{
    return {
        { LabelRole, "label" },
        { PathRole, "path" },
        { IconRole, "icon" },
        { UsedRole, "used" },
        { TotalRole, "total" },
        { UsedTextRole, "usedText" }
    };
}

void DriveListModel::loadDefaults()
{
    beginResetModel();
    m_items.clear();
    endResetModel();
}

void DriveListModel::setDrives(const QVector<DriveItem>& items)
{
    if (m_items == items)
        return;

    const bool sameShape =
        m_items.size() == items.size()
        && std::equal(
            m_items.cbegin(),
            m_items.cend(),
            items.cbegin(),
            [](const DriveItem& current, const DriveItem& next) {
                return current.path == next.path;
            });

    if (sameShape) {
        for (int row = 0; row < m_items.size(); ++row) {
            if (m_items.at(row) == items.at(row))
                continue;

            m_items[row] = items.at(row);
            const QModelIndex modelIndex = index(row, 0);
            emit dataChanged(
                modelIndex,
                modelIndex,
                { LabelRole, PathRole, IconRole, UsedRole, TotalRole, UsedTextRole });
        }
        return;
    }

    beginResetModel();
    m_items = items;
    endResetModel();
}

QVector<DriveListModel::DriveItem> DriveListModel::items() const
{
    return m_items;
}