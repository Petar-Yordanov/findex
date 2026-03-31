#include "navigation/NavigationBreadcrumbModel.h"

NavigationBreadcrumbModel::NavigationBreadcrumbModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int NavigationBreadcrumbModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return static_cast<int>(m_items.size());
}

QVariant NavigationBreadcrumbModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return {};

    const int row = index.row();
    if (row < 0 || row >= m_items.size())
        return {};

    const Item& item = m_items.at(row);

    switch (role)
    {
    case LabelRole:
        return item.label;
    case IconRole:
        return item.icon;
    case PathRole:
        return item.path;
    default:
        return {};
    }
}

QHash<int, QByteArray> NavigationBreadcrumbModel::roleNames() const
{
    return {
        { LabelRole, "label" },
        { IconRole, "icon" },
        { PathRole, "path" }
    };
}

void NavigationBreadcrumbModel::setItems(const QVector<Item>& items)
{
    beginResetModel();
    m_items = items;
    endResetModel();
}

void NavigationBreadcrumbModel::clear()
{
    beginResetModel();
    m_items.clear();
    endResetModel();
}

QVector<NavigationBreadcrumbModel::Item> NavigationBreadcrumbModel::items() const
{
    return m_items;
}