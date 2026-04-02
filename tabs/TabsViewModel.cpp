#include "TabsViewModel.h"

TabsViewModel::TabsViewModel(QObject* parent)
    : QObject(parent)
    , m_tabsModel(this)
{
    m_tabsModel.setTabs({
        { QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("C:/Users/Petar"), true },
        { QStringLiteral("Local Disk (C:)"), QStringLiteral("hard-drive"), QStringLiteral("C:/"), false }
    });
}

TabListModel* TabsViewModel::tabsModel()
{
    return &m_tabsModel;
}

int TabsViewModel::currentIndex() const
{
    return m_currentIndex;
}

int TabsViewModel::editingIndex() const
{
    return m_editingIndex;
}

QString TabsViewModel::editingTitle() const
{
    return m_editingTitle;
}

void TabsViewModel::setEditingTitle(const QString& value)
{
    if (m_editingTitle == value)
        return;

    m_editingTitle = value;
    emit editingTitleChanged();
}

QVariantList TabsViewModel::saveState() const
{
    QVariantList result;
    const auto tabs = m_tabsModel.tabs();

    for (const auto& tab : tabs)
    {
        QVariantMap item;
        item.insert(QStringLiteral("title"), tab.title);
        item.insert(QStringLiteral("icon"), tab.icon);
        item.insert(QStringLiteral("path"), tab.path);
        result.push_back(item);
    }

    return result;
}

void TabsViewModel::loadState(const QVariantList& tabs, int currentIndex)
{
    QVector<TabListModel::TabItem> items;

    for (const QVariant& value : tabs)
    {
        const QVariantMap map = value.toMap();
        const QString title = map.value(QStringLiteral("title")).toString().trimmed();
        const QString icon = map.value(QStringLiteral("icon")).toString().trimmed();
        const QString path = map.value(QStringLiteral("path")).toString().trimmed();

        if (title.isEmpty() || path.isEmpty())
            continue;

        items.push_back({
            title,
            icon.isEmpty() ? QStringLiteral("folder") : icon,
            path,
            false
        });
    }

    if (items.isEmpty()) {
        items.push_back({ QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("C:/Users/Petar"), true });
    }

    const int safeIndex = qBound(0, currentIndex, items.size() - 1);
    for (int i = 0; i < items.size(); ++i)
        items[i].active = (i == safeIndex);

    m_tabsModel.setTabs(items);
    setCurrentIndexInternal(safeIndex);
    emit tabsStateChanged();
}

void TabsViewModel::addTab()
{
    cancelRenameTab();
    m_tabsModel.addTab(QStringLiteral("New Tab"), QStringLiteral("folder"), QStringLiteral("C:/"));
    setCurrentIndexInternal(m_tabsModel.rowCount() - 1);
    m_tabsModel.activateTab(m_currentIndex);
    emit tabsStateChanged();

    const auto dataIndex = m_tabsModel.index(m_currentIndex, 0);
    emit tabAdded(
        m_currentIndex,
        m_tabsModel.data(dataIndex, TabListModel::TitleRole).toString(),
        m_tabsModel.data(dataIndex, TabListModel::PathRole).toString());
}

void TabsViewModel::closeTab(int index)
{
    if (m_tabsModel.rowCount() <= 1)
        return;

    const QString title =
        m_tabsModel.data(m_tabsModel.index(index, 0), TabListModel::TitleRole).toString();

    m_tabsModel.closeTab(index);

    if (m_currentIndex >= m_tabsModel.rowCount())
        setCurrentIndexInternal(m_tabsModel.rowCount() - 1);
    else
        m_tabsModel.activateTab(m_currentIndex);

    if (m_editingIndex == index)
        cancelRenameTab();
    else if (m_editingIndex > index)
        setEditingIndexInternal(m_editingIndex - 1);

    emit tabsStateChanged();
    emit tabClosed(index, title);
}

void TabsViewModel::activateTab(int index)
{
    if (index < 0 || index >= m_tabsModel.rowCount())
        return;

    if (m_editingIndex >= 0 && m_editingIndex != index)
        cancelRenameTab();

    setCurrentIndexInternal(index);
    m_tabsModel.activateTab(index);
    emit tabsStateChanged();

    const auto dataIndex = m_tabsModel.index(index, 0);
    emit tabActivated(
        index,
        m_tabsModel.data(dataIndex, TabListModel::TitleRole).toString(),
        m_tabsModel.data(dataIndex, TabListModel::PathRole).toString());
}

void TabsViewModel::activateTabForDrop(int index)
{
    activateTab(index);
}

void TabsViewModel::beginRenameTab(int index)
{
    if (index < 0 || index >= m_tabsModel.rowCount())
        return;

    setCurrentIndexInternal(index);
    m_tabsModel.activateTab(index);

    setEditingIndexInternal(index);
    setEditingTitle(m_tabsModel.data(m_tabsModel.index(index, 0), TabListModel::TitleRole).toString());
}

void TabsViewModel::commitRenameTab(int index, const QString& title)
{
    if (index < 0 || index >= m_tabsModel.rowCount())
    {
        cancelRenameTab();
        return;
    }

    const QString trimmed = title.trimmed();
    if (!trimmed.isEmpty()) {
        m_tabsModel.renameTab(index, trimmed);
        emit tabsStateChanged();
        emit tabRenamed(index, trimmed);
    }

    cancelRenameTab();
}

void TabsViewModel::cancelRenameTab()
{
    setEditingIndexInternal(-1);
    setEditingTitle(QString());
}

void TabsViewModel::moveTab(int from, int to)
{
    if (from < 0 || to < 0 || from >= m_tabsModel.rowCount() || to >= m_tabsModel.rowCount() || from == to)
        return;

    m_tabsModel.moveTab(from, to);

    if (m_editingIndex == from)
        setEditingIndexInternal(to);
    else if (from < m_editingIndex && to >= m_editingIndex)
        setEditingIndexInternal(m_editingIndex - 1);
    else if (from > m_editingIndex && to <= m_editingIndex)
        setEditingIndexInternal(m_editingIndex + 1);

    setCurrentIndexInternal(to);
    m_tabsModel.activateTab(to);
    emit tabsStateChanged();
    emit tabMoved(from, to);
}

void TabsViewModel::setCurrentTabPath(const QString& path)
{
    m_tabsModel.setTabPath(m_currentIndex, path);
    emit tabsStateChanged();
}

void TabsViewModel::setCurrentIndexInternal(int index)
{
    if (m_currentIndex == index)
        return;

    m_currentIndex = index;
    emit currentIndexChanged();
}

void TabsViewModel::setEditingIndexInternal(int index)
{
    if (m_editingIndex == index)
        return;

    m_editingIndex = index;
    emit editingIndexChanged();
}