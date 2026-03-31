#pragma once

#include <QObject>
#include <QString>

class StatusBarViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(int selectedItems READ selectedItems NOTIFY selectedItemsChanged)
    Q_PROPERTY(int notificationCount READ notificationCount NOTIFY notificationCountChanged)
    Q_PROPERTY(QString currentViewMode READ currentViewMode NOTIFY currentViewModeChanged)
    Q_PROPERTY(QString viewModeIcon READ viewModeIcon NOTIFY currentViewModeChanged)
    Q_PROPERTY(QString itemsText READ itemsText NOTIFY itemsTextChanged)

public:
    explicit StatusBarViewModel(QObject* parent = nullptr);

    int totalItems() const;
    int selectedItems() const;
    int notificationCount() const;
    QString currentViewMode() const;
    QString viewModeIcon() const;
    QString itemsText() const;

    Q_INVOKABLE void setTotalItems(int value);
    Q_INVOKABLE void setSelectedItems(int value);
    Q_INVOKABLE void setNotificationCount(int value);
    Q_INVOKABLE void setCurrentViewMode(const QString& value);

signals:
    void totalItemsChanged();
    void selectedItemsChanged();
    void notificationCountChanged();
    void currentViewModeChanged();
    void itemsTextChanged();

private:
    QString iconForViewMode(const QString& mode) const;
    void emitItemsTextIfNeeded(const QString& previousText);

private:
    int m_totalItems = 0;
    int m_selectedItems = 0;
    int m_notificationCount = 0;
    QString m_currentViewMode = QStringLiteral("Details");
};