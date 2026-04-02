#include "statusbar/StatusBarViewModel.h"

#include <QTimer>

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
    if (m_selectedItems > 0) {
        return QString::number(m_totalItems) + QStringLiteral(" items  ")
        + QString::number(m_selectedItems) + QStringLiteral(" selected");
    }

    return QString::number(m_totalItems) + QStringLiteral(" items");
}

QVariantList StatusBarViewModel::notifications() const
{
    return m_notifications;
}

QVariantList StatusBarViewModel::toastNotifications() const
{
    return m_toastNotifications;
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

int StatusBarViewModel::pushNotification(const QString& title,
                                         const QString& kind,
                                         int progress,
                                         bool autoClose,
                                         bool showToast)
{
    const int id = m_nextNotificationId++;

    QVariantMap item;
    item.insert(QStringLiteral("id"), id);
    item.insert(QStringLiteral("title"), title);
    item.insert(QStringLiteral("kind"), kind.trimmed().isEmpty() ? QStringLiteral("info") : kind.trimmed());
    item.insert(QStringLiteral("progress"), progress);
    item.insert(QStringLiteral("autoClose"), autoClose);
    item.insert(QStringLiteral("done"), false);

    m_notifications.push_back(item);
    emit notificationsChanged();
    updateNotificationCountFromList();

    if (showToast) {
        upsertToastFromNotification(item);
    }

    if (autoClose && progress < 0) {
        QTimer::singleShot(5000, this, [this, id]() {
            dismissToast(id);
        });
    }

    return id;
}

void StatusBarViewModel::dismissNotification(int id)
{
    bool removed = false;
    dismissFromList(m_notifications, id, &removed);
    if (removed) {
        emit notificationsChanged();
        updateNotificationCountFromList();
    }
}

void StatusBarViewModel::dismissToast(int id)
{
    bool removed = false;
    dismissFromList(m_toastNotifications, id, &removed);
    if (removed)
        emit toastNotificationsChanged();
}

void StatusBarViewModel::updateNotificationProgress(int id, int progress, bool done)
{
    bool foundPersistent = false;
    updateListEntry(m_notifications, id, progress, done, &foundPersistent);
    if (foundPersistent) {
        emit notificationsChanged();
        updateNotificationCountFromList();
    }

    bool foundToast = false;
    updateListEntry(m_toastNotifications, id, progress, done, &foundToast);
    if (foundToast)
        emit toastNotificationsChanged();

    if (done) {
        QTimer::singleShot(5000, this, [this, id]() {
            dismissToast(id);
        });
    }
}

void StatusBarViewModel::startTestProgress()
{
    const int id = pushNotification(QStringLiteral("Test operation in progress"),
                                    QStringLiteral("progress"),
                                    0,
                                    false,
                                    true);

    auto* progress = new int(0);
    auto* timer = new QTimer(this);
    timer->setInterval(180);

    connect(timer, &QTimer::timeout, this, [this, timer, progress, id]() {
        *progress += 5;
        const bool done = *progress >= 100;
        updateNotificationProgress(id, done ? 100 : *progress, done);

        if (done) {
            timer->stop();
            timer->deleteLater();
            delete progress;
        }
    });

    timer->start();
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

void StatusBarViewModel::updateNotificationCountFromList()
{
    setNotificationCount(m_notifications.size());
}

void StatusBarViewModel::upsertToastFromNotification(const QVariantMap& item)
{
    const int id = item.value(QStringLiteral("id")).toInt();

    for (int i = 0; i < m_toastNotifications.size(); ++i) {
        QVariantMap existing = m_toastNotifications.at(i).toMap();
        if (existing.value(QStringLiteral("id")).toInt() != id)
            continue;

        m_toastNotifications[i] = item;
        emit toastNotificationsChanged();
        return;
    }

    m_toastNotifications.push_back(item);
    emit toastNotificationsChanged();
}

void StatusBarViewModel::dismissFromList(QVariantList& list, int id, bool* removed)
{
    if (removed)
        *removed = false;

    for (int i = 0; i < list.size(); ++i) {
        if (list.at(i).toMap().value(QStringLiteral("id")).toInt() != id)
            continue;

        list.removeAt(i);
        if (removed)
            *removed = true;
        return;
    }
}

void StatusBarViewModel::updateListEntry(QVariantList& list,
                                         int id,
                                         int progress,
                                         bool done,
                                         bool* found)
{
    if (found)
        *found = false;

    for (int i = 0; i < list.size(); ++i) {
        QVariantMap item = list.at(i).toMap();
        if (item.value(QStringLiteral("id")).toInt() != id)
            continue;

        item.insert(QStringLiteral("progress"), qBound(0, progress, 100));
        item.insert(QStringLiteral("done"), done);
        item.insert(QStringLiteral("autoClose"), done);

        list[i] = item;

        if (found)
            *found = true;
        return;
    }
}