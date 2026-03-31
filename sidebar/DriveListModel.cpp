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
    m_items = {
        { "Local Disk (C:)", "hard-drive", 500ll * 1024 * 1024 * 1024, 1000ll * 1024 * 1024 * 1024, "0.5 TB used of 1 TB" },
        { "Data (D:)", "storage", 370ll * 1024 * 1024 * 1024, 1000ll * 1024 * 1024 * 1024, "0.37 TB used of 1 TB" },
        { "Backup (E:)", "save", 910ll * 1024 * 1024 * 1024, 1000ll * 1024 * 1024 * 1024, "0.91 TB used of 1 TB" },
        { "USB Drive (F:)", "usb", 180ll * 1024 * 1024 * 1024, 1000ll * 1024 * 1024 * 1024, "0.18 TB used of 1 TB" }
    };

    endResetModel();
}