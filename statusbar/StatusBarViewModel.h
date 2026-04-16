#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class StatusBarViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(int selectedItems READ selectedItems NOTIFY selectedItemsChanged)
    Q_PROPERTY(int notificationCount READ notificationCount NOTIFY notificationCountChanged)
    Q_PROPERTY(QString currentViewMode READ currentViewMode NOTIFY currentViewModeChanged)
    Q_PROPERTY(QString viewModeIcon READ viewModeIcon NOTIFY currentViewModeChanged)
    Q_PROPERTY(QString itemsText READ itemsText NOTIFY itemsTextChanged)
    Q_PROPERTY(QVariantList notifications READ notifications NOTIFY notificationsChanged)
    Q_PROPERTY(QVariantList toastNotifications READ toastNotifications NOTIFY toastNotificationsChanged)

public:
    explicit StatusBarViewModel(QObject* parent = nullptr);

    int totalItems() const;
    int selectedItems() const;
    int notificationCount() const;
    QString currentViewMode() const;
    QString viewModeIcon() const;
    QString itemsText() const;
    QVariantList notifications() const;
    QVariantList toastNotifications() const;

    Q_INVOKABLE void setTotalItems(int value);
    Q_INVOKABLE void setSelectedItems(int value);
    Q_INVOKABLE void setNotificationCount(int value);
    Q_INVOKABLE void setCurrentViewMode(const QString& value);

    Q_INVOKABLE int pushNotification(const QString& title,
                                     const QString& details = QString(),
                                     const QString& kind = QStringLiteral("info"),
                                     int progress = -1,
                                     bool autoClose = true,
                                     bool showToast = true);

    Q_INVOKABLE void dismissNotification(int id);
    Q_INVOKABLE void dismissToast(int id);
    Q_INVOKABLE void updateNotificationProgress(int id,
                                                int progress,
                                                bool done = false,
                                                const QString& details = QString(),
                                                const QString& title = QString());
    Q_INVOKABLE void startTestProgress();

signals:
    void totalItemsChanged();
    void selectedItemsChanged();
    void notificationCountChanged();
    void currentViewModeChanged();
    void itemsTextChanged();
    void notificationsChanged();
    void toastNotificationsChanged();

private:
    QString iconForViewMode(const QString& mode) const;
    void emitItemsTextIfNeeded(const QString& previousText);
    void updateNotificationCountFromList();

    void upsertToastFromNotification(const QVariantMap& item);
    void dismissFromList(QVariantList& list, int id, bool* removed = nullptr);
    void updateListEntry(QVariantList& list,
                         int id,
                         int progress,
                         bool done,
                         const QString& details,
                         const QString& title,
                         bool* found = nullptr);

private:
    int m_totalItems = 0;
    int m_selectedItems = 0;
    int m_notificationCount = 0;
    QString m_currentViewMode = QStringLiteral("Details");

    QVariantList m_notifications;
    QVariantList m_toastNotifications;

    int m_nextNotificationId = 1;
};