#include "SidebarTreeModel.h"

SidebarTreeModel::SidebarTreeModel(QObject* parent)
    : QAbstractItemModel(parent)
    , m_root(new SidebarTreeItem)
{
    loadDefaults();
}

SidebarTreeModel::~SidebarTreeModel()
{
    delete m_root;
    m_root = nullptr;
}

SidebarTreeItem* SidebarTreeModel::makeItem(
    const QString& label,
    const QString& icon,
    const QString& kind,
    const QString& path,
    bool section,
    bool expandedByDefault,
    SidebarTreeItem* parent)
{
    auto* item = new SidebarTreeItem;
    item->data.label = label;
    item->data.icon = icon;
    item->data.kind = kind;
    item->data.path = path;
    item->data.section = section;
    item->data.expandedByDefault = expandedByDefault;
    item->parent = parent;
    return item;
}

SidebarTreeItem* SidebarTreeModel::itemFromIndex(const QModelIndex& index) const
{
    if (index.isValid())
        return static_cast<SidebarTreeItem*>(index.internalPointer());

    return m_root;
}

QModelIndex SidebarTreeModel::index(int row, int column, const QModelIndex& parentIndex) const
{
    if (column != 0 || row < 0)
        return {};

    SidebarTreeItem* parentItem = itemFromIndex(parentIndex);
    if (!parentItem)
        return {};

    if (row >= parentItem->children.size())
        return {};

    return createIndex(row, column, parentItem->children.at(row));
}

QModelIndex SidebarTreeModel::parent(const QModelIndex& child) const
{
    if (!child.isValid())
        return {};

    auto* childItem = static_cast<SidebarTreeItem*>(child.internalPointer());
    if (!childItem || !childItem->parent || childItem->parent == m_root)
        return {};

    SidebarTreeItem* parentItem = childItem->parent;
    return createIndex(parentItem->rowInParent(), 0, parentItem);
}

int SidebarTreeModel::rowCount(const QModelIndex& parentIndex) const
{
    if (parentIndex.isValid() && parentIndex.column() != 0)
        return 0;

    SidebarTreeItem* parentItem = itemFromIndex(parentIndex);
    return parentItem ? parentItem->children.size() : 0;
}

int SidebarTreeModel::columnCount(const QModelIndex&) const
{
    return 1;
}

QVariant SidebarTreeModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return {};

    auto* item = static_cast<SidebarTreeItem*>(index.internalPointer());
    if (!item)
        return {};

    switch (role) {
    case Qt::DisplayRole:
    case LabelRole:
        return item->data.label;
    case IconRole:
        return item->data.icon;
    case KindRole:
        return item->data.kind;
    case PathRole:
        return item->data.path;
    case SectionRole:
        return item->data.section;
    case ExpandedByDefaultRole:
        return item->data.expandedByDefault;
    case HasChildrenRole:
        return !item->children.isEmpty();
    default:
        return {};
    }
}

QHash<int, QByteArray> SidebarTreeModel::roleNames() const
{
    return {
        { LabelRole, "label" },
        { IconRole, "icon" },
        { KindRole, "kind" },
        { PathRole, "path" },
        { SectionRole, "section" },
        { ExpandedByDefaultRole, "expandedByDefault" },
        { HasChildrenRole, "hasChildren" }
    };
}

QString SidebarTreeModel::label(const QModelIndex& index) const
{
    return data(index, LabelRole).toString();
}

QString SidebarTreeModel::icon(const QModelIndex& index) const
{
    return data(index, IconRole).toString();
}

QString SidebarTreeModel::kind(const QModelIndex& index) const
{
    return data(index, KindRole).toString();
}

QString SidebarTreeModel::path(const QModelIndex& index) const
{
    return data(index, PathRole).toString();
}

bool SidebarTreeModel::section(const QModelIndex& index) const
{
    return data(index, SectionRole).toBool();
}

bool SidebarTreeModel::expandedByDefault(const QModelIndex& index) const
{
    return data(index, ExpandedByDefaultRole).toBool();
}

bool SidebarTreeModel::hasChildrenAt(const QModelIndex& index) const
{
    return data(index, HasChildrenRole).toBool();
}

void SidebarTreeModel::loadDefaults()
{
    beginResetModel();

    qDeleteAll(m_root->children);
    m_root->children.clear();

    auto* quickAccess = makeItem("Quick Access", "", "section", "", true, true, m_root);
    m_root->children.append(quickAccess);

    quickAccess->children.append(makeItem("Recent", "history", "quick", "C:/Users/Petar/Recent", false, false, quickAccess));
    quickAccess->children.append(makeItem("Home", "home", "quick", "C:/Users/Petar", false, false, quickAccess));
    quickAccess->children.append(makeItem("Desktop", "desktop-windows", "quick", "C:/Users/Petar/Desktop", false, false, quickAccess));
    quickAccess->children.append(makeItem("Downloads", "download", "quick", "C:/Users/Petar/Downloads", false, false, quickAccess));
    quickAccess->children.append(makeItem("Documents", "description", "quick", "C:/Users/Petar/Documents", false, false, quickAccess));
    quickAccess->children.append(makeItem("Pictures", "image", "quick", "C:/Users/Petar/Pictures", false, false, quickAccess));
    quickAccess->children.append(makeItem("Music", "music-note", "quick", "C:/Users/Petar/Music", false, false, quickAccess));
    quickAccess->children.append(makeItem("Videos", "movie", "quick", "C:/Users/Petar/Videos", false, false, quickAccess));

    endResetModel();
}