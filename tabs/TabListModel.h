#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

class TabListModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles
    {
        TitleRole = Qt::UserRole + 1,
        IconRole,
        PathRole,
        ActiveRole
    };
    Q_ENUM(Roles)

    struct TabItem
    {
        QString title;
        QString icon;
        QString path;
        bool active = false;
    };

    explicit TabListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setTabs(const QVector<TabItem>& tabs);
    void addTab(const QString& title, const QString& icon = QStringLiteral("folder"), const QString& path = QStringLiteral("C:/"));
    void closeTab(int index);
    void activateTab(int index);
    void renameTab(int index, const QString& title);
    void setTabPath(int index, const QString& path);
    void moveTab(int from, int to);

    QVector<TabItem> tabs() const;

private:
    QVector<TabItem> m_tabs;
};