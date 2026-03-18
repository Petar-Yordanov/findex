#include "FileManagerSessionService.h"

FileManagerSessionService::FileManagerSessionService(QObject* parent)
    : QObject(parent)
{
    m_tabs = {
        QVariantMap{{"title", "Home"}, {"icon", "home"}},
        QVariantMap{{"title", "Local Disk (C:)"}, {"icon", "hard-drive"}}
    };
    m_currentTabIndex = 1;
}

int FileManagerSessionService::currentTabIndex() const
{
    return m_currentTabIndex;
}

QVariantList FileManagerSessionService::tabs() const
{
    return m_tabs;
}

void FileManagerSessionService::activateTab(int index)
{
    if (index >= 0 && index < m_tabs.size())
        m_currentTabIndex = index;
}

void FileManagerSessionService::addTab(const QString& title)
{
    const QString finalTitle = title.trimmed().isEmpty() ? QStringLiteral("New Tab") : title.trimmed();
    m_tabs.append(QVariantMap{{"title", finalTitle}, {"icon", "folder"}});
    m_currentTabIndex = m_tabs.size() - 1;
}

void FileManagerSessionService::duplicateTab(int index)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    QVariantMap copy = m_tabs[index].toMap();
    copy["title"] = copy.value("title").toString() + QStringLiteral(" Copy");
    m_tabs.insert(index + 1, copy);
    m_currentTabIndex = index + 1;
}

void FileManagerSessionService::closeTab(int index)
{
    if (m_tabs.size() <= 1 || index < 0 || index >= m_tabs.size())
        return;

    m_tabs.removeAt(index);
    if (m_currentTabIndex >= m_tabs.size())
        m_currentTabIndex = m_tabs.size() - 1;
    if (m_currentTabIndex < 0)
        m_currentTabIndex = 0;
}

void FileManagerSessionService::renameTab(int index, const QString& title)
{
    if (index < 0 || index >= m_tabs.size())
        return;

    QVariantMap tab = m_tabs[index].toMap();
    tab["title"] = title.trimmed().isEmpty() ? tab.value("title").toString() : title.trimmed();
    m_tabs[index] = tab;
}

void FileManagerSessionService::moveTab(int from, int to)
{
    if (from == to || from < 0 || to < 0 || from >= m_tabs.size() || to >= m_tabs.size())
        return;

    m_tabs.move(from, to);

    if (m_currentTabIndex == from)
        m_currentTabIndex = to;
    else if (m_currentTabIndex > from && m_currentTabIndex <= to)
        --m_currentTabIndex;
    else if (m_currentTabIndex < from && m_currentTabIndex >= to)
        ++m_currentTabIndex;
}