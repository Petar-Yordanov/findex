#include "TabsViewModel.h"

#include <QDir>
#include <QFileInfo>

TabsViewModel::TabsViewModel(QObject* parent)
    : QObject(parent)
    , m_tabsModel(this)
{
    m_tabsModel.setTabs({
        { QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("C:/Users/Petar"), true, false },
        { QStringLiteral("Local Disk (C:)"), QStringLiteral("hard-drive"), QStringLiteral("C:/"), false, false }
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
        item.insert(QStringLiteral("customTitle"), tab.customTitle);
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
        const QString path = map.value(QStringLiteral("path")).toString().trimmed();
        if (path.isEmpty())
            continue;

        const QString savedTitle = map.value(QStringLiteral("title")).toString().trimmed();
        const QString icon = map.value(QStringLiteral("icon")).toString().trimmed();
        const bool customTitle = map.value(QStringLiteral("customTitle"), false).toBool();

        const QString resolvedTitle = customTitle
                                          ? (savedTitle.isEmpty() ? defaultTitleForPath(path) : savedTitle)
                                          : defaultTitleForPath(path);

        items.push_back({
            resolvedTitle,
            icon.isEmpty() ? QStringLiteral("folder") : icon,
            path,
            false,
            customTitle
        });
    }

    if (items.isEmpty()) {
        items.push_back({ QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("C:/Users/Petar"), true, false });
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
    const QString path = QStringLiteral("C:/");
    m_tabsModel.addTab(defaultTitleForPath(path), QStringLiteral("folder"), path, false);
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
    const auto currentTabs = m_tabsModel.tabs();
    if (index < 0 || index >= currentTabs.size() || currentTabs.size() <= 1)
        return;

    cancelRenameTab();

    QVector<TabListModel::TabItem> tabs = currentTabs;
    const QString title = tabs.at(index).title;
    const bool currentTabWillChange = (index == m_currentIndex);

    int nextCurrentIndex = m_currentIndex;
    if (index < m_currentIndex)
        --nextCurrentIndex;
    else if (index == m_currentIndex)
        nextCurrentIndex = qMin(index, tabs.size() - 2);

    tabs.removeAt(index);
    applyTabsState(tabs, nextCurrentIndex);

    emit tabsStateChanged();
    emit tabClosed(index, title);

    if (currentTabWillChange)
        emitCurrentTabActivated();
}

void TabsViewModel::closeOtherTabs(int index)
{
    const auto currentTabs = m_tabsModel.tabs();
    if (index < 0 || index >= currentTabs.size() || currentTabs.size() <= 1)
        return;

    cancelRenameTab();

    const bool currentTabWillChange = (m_currentIndex != index);
    QVector<TabListModel::TabItem> tabs;
    tabs.push_back(currentTabs.at(index));
    applyTabsState(tabs, 0);
    emit tabsStateChanged();

    if (currentTabWillChange)
        emitCurrentTabActivated();
}

void TabsViewModel::closeTabsToLeft(int index)
{
    const auto currentTabs = m_tabsModel.tabs();
    if (index <= 0 || index >= currentTabs.size())
        return;

    cancelRenameTab();

    QVector<TabListModel::TabItem> tabs;
    tabs.reserve(currentTabs.size() - index);
    for (int i = index; i < currentTabs.size(); ++i)
        tabs.push_back(currentTabs.at(i));

    const bool currentTabWillChange = (m_currentIndex < index);
    const int nextCurrentIndex = currentTabWillChange ? 0 : (m_currentIndex - index);
    applyTabsState(tabs, nextCurrentIndex);
    emit tabsStateChanged();

    if (currentTabWillChange)
        emitCurrentTabActivated();
}

void TabsViewModel::closeTabsToRight(int index)
{
    const auto currentTabs = m_tabsModel.tabs();
    if (index < 0 || index >= currentTabs.size() - 1)
        return;

    cancelRenameTab();

    QVector<TabListModel::TabItem> tabs;
    tabs.reserve(index + 1);
    for (int i = 0; i <= index; ++i)
        tabs.push_back(currentTabs.at(i));

    const bool currentTabWillChange = (m_currentIndex > index);
    const int nextCurrentIndex = currentTabWillChange ? index : m_currentIndex;
    applyTabsState(tabs, nextCurrentIndex);
    emit tabsStateChanged();

    if (currentTabWillChange)
        emitCurrentTabActivated();
}

void TabsViewModel::duplicateTab(int index)
{
    const auto currentTabs = m_tabsModel.tabs();
    if (index < 0 || index >= currentTabs.size())
        return;

    cancelRenameTab();

    QVector<TabListModel::TabItem> tabs = currentTabs;
    tabs.insert(index + 1, currentTabs.at(index));
    applyTabsState(tabs, index + 1);
    emit tabsStateChanged();
    emit tabAdded(index + 1, tabs.at(index + 1).title, tabs.at(index + 1).path);
    emitCurrentTabActivated();
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
    const QString currentPath =
        m_tabsModel.data(m_tabsModel.index(index, 0), TabListModel::PathRole).toString();

    const QString resolvedTitle = trimmed.isEmpty()
                                      ? defaultTitleForPath(currentPath)
                                      : trimmed;

    const bool customTitle = !trimmed.isEmpty();

    m_tabsModel.renameTab(index, resolvedTitle, customTitle);
    emit tabsStateChanged();
    emit tabRenamed(index, resolvedTitle);

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
    if (m_currentIndex < 0 || m_currentIndex >= m_tabsModel.rowCount())
        return;

    m_tabsModel.setTabPath(m_currentIndex, path);
    emit tabsStateChanged();
}

void TabsViewModel::syncCurrentTabToPath(const QString& path)
{
    if (m_currentIndex < 0 || m_currentIndex >= m_tabsModel.rowCount())
        return;

    auto tabs = m_tabsModel.tabs();
    if (m_currentIndex < 0 || m_currentIndex >= tabs.size())
        return;

    const auto& current = tabs.at(m_currentIndex);

    m_tabsModel.setTabPath(m_currentIndex, path);

    if (!current.customTitle)
        m_tabsModel.setTabTitle(m_currentIndex, defaultTitleForPath(path), false);

    emit tabsStateChanged();
}

void TabsViewModel::applyTabsState(const QVector<TabListModel::TabItem>& tabs, int currentIndex)
{
    QVector<TabListModel::TabItem> nextTabs = tabs;
    if (nextTabs.isEmpty())
        nextTabs.push_back({ QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("C:/Users/Petar"), true, false });

    const int safeIndex = qBound(0, currentIndex, nextTabs.size() - 1);
    for (int i = 0; i < nextTabs.size(); ++i)
        nextTabs[i].active = (i == safeIndex);

    m_tabsModel.setTabs(nextTabs);
    setCurrentIndexInternal(safeIndex);
}

void TabsViewModel::emitCurrentTabActivated()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_tabsModel.rowCount())
        return;

    const auto dataIndex = m_tabsModel.index(m_currentIndex, 0);
    emit tabActivated(
        m_currentIndex,
        m_tabsModel.data(dataIndex, TabListModel::TitleRole).toString(),
        m_tabsModel.data(dataIndex, TabListModel::PathRole).toString());
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

QString TabsViewModel::defaultTitleForPath(const QString& path) const
{
    const QString normalized = QDir::fromNativeSeparators(path.trimmed());
    if (normalized.isEmpty())
        return QStringLiteral("Tab");

    QFileInfo info(normalized);
    QString name = info.fileName();

    if (!name.isEmpty())
        return name;

#ifdef Q_OS_WINDOWS
    QString root = normalized;
    if (root.endsWith('/'))
        root.chop(1);
    if (!root.isEmpty())
        return root;
#endif

    return normalized;
}