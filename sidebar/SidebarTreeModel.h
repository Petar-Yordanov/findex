#pragma once

#include <QAbstractItemModel>
#include "SidebarTreeItem.h"

class SidebarTreeModel final : public QAbstractItemModel
{
    Q_OBJECT

public:
    enum Roles
    {
        LabelRole = Qt::UserRole + 1,
        IconRole,
        KindRole,
        SectionRole,
        ExpandedByDefaultRole,
        HasChildrenRole
    };
    Q_ENUM(Roles)

    explicit SidebarTreeModel(QObject* parent = nullptr);
    ~SidebarTreeModel() override;

    QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex& child) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE QString label(const QModelIndex& index) const;
    Q_INVOKABLE QString icon(const QModelIndex& index) const;
    Q_INVOKABLE QString kind(const QModelIndex& index) const;
    Q_INVOKABLE bool section(const QModelIndex& index) const;
    Q_INVOKABLE bool expandedByDefault(const QModelIndex& index) const;
    Q_INVOKABLE bool hasChildrenAt(const QModelIndex& index) const;

    void loadDefaults();

private:
    SidebarTreeItem* m_root = nullptr;

    SidebarTreeItem* itemFromIndex(const QModelIndex& index) const;
    static SidebarTreeItem* makeItem(
        const QString& label,
        const QString& icon,
        const QString& kind,
        bool section,
        bool expandedByDefault,
        SidebarTreeItem* parent);
};