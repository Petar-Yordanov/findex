#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

class NavigationBreadcrumbModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles
    {
        LabelRole = Qt::UserRole + 1,
        IconRole
    };
    Q_ENUM(Roles)

    struct Item
    {
        QString label;
        QString icon;
    };

    explicit NavigationBreadcrumbModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setItems(const QVector<Item>& items);
    void clear();

    QVector<Item> items() const;

private:
    QVector<Item> m_items;
};