#include "statusbar/StatusBarViewModel.h"

StatusBarViewModel::StatusBarViewModel(QObject* parent)
    : QObject(parent)
{
}

int StatusBarViewModel::totalItems() const
{
    return m_totalItems;
}

int StatusBarViewModel::selectedItems() const
{
    return m_selectedItems;
}

int StatusBarViewModel::notificationCount() const
{
    return m_notificationCount;
}

QString StatusBarViewModel::currentViewMode() const
{
    return m_currentViewMode;
}

QString StatusBarViewModel::viewModeIcon() const
{
    return iconForViewMode(m_currentViewMode);
}

QString StatusBarViewModel::itemsText() const
{
    if (m_selectedItems > 0)
        return QString::number(m_totalItems) + QStringLiteral(" items  ")
               + QString::number(m_selectedItems) + QStringLiteral(" selected");

    return QString::number(m_totalItems) + QStringLiteral(" items");
}

void StatusBarViewModel::setTotalItems(int value)
{
    if (value < 0)
        value = 0;

    if (m_totalItems == value)
        return;

    const QString previousText = itemsText();
    m_totalItems = value;
    emit totalItemsChanged();
    emitItemsTextIfNeeded(previousText);
}

void StatusBarViewModel::setSelectedItems(int value)
{
    if (value < 0)
        value = 0;

    if (m_selectedItems == value)
        return;

    const QString previousText = itemsText();
    m_selectedItems = value;
    emit selectedItemsChanged();
    emitItemsTextIfNeeded(previousText);
}

void StatusBarViewModel::setNotificationCount(int value)
{
    if (value < 0)
        value = 0;

    if (m_notificationCount == value)
        return;

    m_notificationCount = value;
    emit notificationCountChanged();
}

void StatusBarViewModel::setCurrentViewMode(const QString& value)
{
    const QString resolved = value.trimmed().isEmpty()
    ? QStringLiteral("Details")
    : value.trimmed();

    if (m_currentViewMode == resolved)
        return;

    m_currentViewMode = resolved;
    emit currentViewModeChanged();
}

QString StatusBarViewModel::iconForViewMode(const QString& mode) const
{
    if (mode == QStringLiteral("Details"))
        return QStringLiteral("detailed-view");
    if (mode == QStringLiteral("Tiles"))
        return QStringLiteral("tile-view");
    if (mode == QStringLiteral("Compact"))
        return QStringLiteral("list-view");
    if (mode == QStringLiteral("Large icons"))
        return QStringLiteral("grid-view");

    return QStringLiteral("list-view");
}

void StatusBarViewModel::emitItemsTextIfNeeded(const QString& previousText)
{
    if (previousText != itemsText())
        emit itemsTextChanged();
}