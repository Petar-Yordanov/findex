#include "TabListModel.h"

TabListModel::TabListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int TabListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_tabs.size();
}

QVariant TabListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tabs.size())
        return {};

    const TabItem& item = m_tabs.at(index.row());

    switch (role)
    {
    case TitleRole:
        return item.title;
    case IconRole:
        return item.icon;
    case PathRole:
        return item.path;
    case ActiveRole:
        return item.active;
    default:
        return {};
    }
}

QHash<int, QByteArray> TabListModel::roleNames() const
{
    return {
        { TitleRole, "title" },
        { IconRole, "icon" },
        { PathRole, "path" },
        { ActiveRole, "active" }
    };
}

void TabListModel::setTabs(const QVector<TabItem>& tabs)
{
    beginResetModel();
    m_tabs = tabs;
    endResetModel();
}

void TabListModel::addTab(const QString& title, const QString& icon, const QString& path)
{
    const int previousCount = m_tabs.size();

    for (int i = 0; i < m_tabs.size(); ++i)
        m_tabs[i].active = false;

    if (previousCount > 0)
        emit dataChanged(index(0, 0), index(previousCount - 1, 0), { ActiveRole });

    const int row = m_tabs.size();
    beginInsertRows(QModelIndex(), row, row);
    m_tabs.push_back(TabItem{ title, icon, path, true });
    endInsertRows();
}

void TabListModel::closeTab(int index)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    const bool wasActive = m_tabs.at(index).active;

    beginRemoveRows(QModelIndex(), index, index);
    m_tabs.removeAt(index);
    endRemoveRows();

    if (m_tabs.isEmpty())
    {
        addTab(QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("C:/Users/Petar"));
        return;
    }

    if (wasActive)
    {
        const int nextIndex = qMin(index, m_tabs.size() - 1);
        activateTab(nextIndex);
    }
}

void TabListModel::activateTab(int index)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    for (int i = 0; i < m_tabs.size(); ++i)
    {
        const bool nextActive = (i == index);
        if (m_tabs[i].active != nextActive)
        {
            m_tabs[i].active = nextActive;
            const QModelIndex modelIndex = this->index(i, 0);
            emit dataChanged(modelIndex, modelIndex, { ActiveRole });
        }
    }
}

void TabListModel::renameTab(int index, const QString& title)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    if (m_tabs[index].title == title)
        return;

    m_tabs[index].title = title;
    const QModelIndex modelIndex = this->index(index, 0);
    emit dataChanged(modelIndex, modelIndex, { TitleRole });
}

void TabListModel::setTabPath(int index, const QString& path)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    if (m_tabs[index].path == path)
        return;

    m_tabs[index].path = path;
    const QModelIndex modelIndex = this->index(index, 0);
    emit dataChanged(modelIndex, modelIndex, { PathRole });
}

void TabListModel::moveTab(int from, int to)
{
    if (from < 0 || to < 0 || from >= m_tabs.size() || to >= m_tabs.size() || from == to)
        return;

    beginMoveRows(QModelIndex(), from, from, QModelIndex(), from < to ? to + 1 : to);
    m_tabs.move(from, to);
    endMoveRows();
}

QVector<TabListModel::TabItem> TabListModel::tabs() const
{
    return m_tabs;
}