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

void TabsViewModel::addTab()
{
    cancelRenameTab();
    m_tabsModel.addTab(QStringLiteral("New Tab"), QStringLiteral("folder"), QStringLiteral("C:/"));
    setCurrentIndexInternal(m_tabsModel.rowCount() - 1);
    m_tabsModel.activateTab(m_currentIndex);
}

void TabsViewModel::closeTab(int index)
{
    if (m_tabsModel.rowCount() <= 1)
        return;

    m_tabsModel.closeTab(index);

    if (m_currentIndex >= m_tabsModel.rowCount())
        setCurrentIndexInternal(m_tabsModel.rowCount() - 1);
    else
        m_tabsModel.activateTab(m_currentIndex);

    if (m_editingIndex == index)
        cancelRenameTab();
    else if (m_editingIndex > index)
        setEditingIndexInternal(m_editingIndex - 1);
}

void TabsViewModel::activateTab(int index)
{
    if (index < 0 || index >= m_tabsModel.rowCount())
        return;

    if (m_editingIndex >= 0 && m_editingIndex != index)
        cancelRenameTab();

    setCurrentIndexInternal(index);
    m_tabsModel.activateTab(index);
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
    if (!trimmed.isEmpty())
        m_tabsModel.renameTab(index, trimmed);

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
}

void TabsViewModel::setCurrentTabPath(const QString& path)
{
    m_tabsModel.setTabPath(m_currentIndex, path);
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