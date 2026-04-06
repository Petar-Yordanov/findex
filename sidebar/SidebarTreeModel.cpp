#include "SidebarTreeModel.h"

#include <QDir>
#include <QStandardPaths>

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

    auto norm = [](const QString& p) -> QString {
        return QDir::fromNativeSeparators(QDir(p).absolutePath());
    };

    const QString home = norm(QDir::homePath());
    const QString desktop = norm(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation));
    const QString documents = norm(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation));
    const QString downloads = norm(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
    const QString pictures = norm(QStandardPaths::writableLocation(QStandardPaths::PicturesLocation));
    const QString music = norm(QStandardPaths::writableLocation(QStandardPaths::MusicLocation));
    const QString videos = norm(QStandardPaths::writableLocation(QStandardPaths::MoviesLocation));

#ifdef Q_OS_WINDOWS
    const QString recent = norm(QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
                                + QStringLiteral("/AppData/Roaming/Microsoft/Windows/Recent"));
#else
    const QString recent;
#endif

    auto* quickAccess = makeItem("Quick Access", "", "section", "", true, true, m_root);
    m_root->children.append(quickAccess);

    if (!recent.isEmpty())
        quickAccess->children.append(makeItem("Recent", "history", "quick", recent, false, false, quickAccess));

    if (!home.isEmpty())
        quickAccess->children.append(makeItem("Home", "home", "quick", home, false, false, quickAccess));

    if (!desktop.isEmpty())
        quickAccess->children.append(makeItem("Desktop", "desktop-windows", "quick", desktop, false, false, quickAccess));

    if (!downloads.isEmpty())
        quickAccess->children.append(makeItem("Downloads", "download", "quick", downloads, false, false, quickAccess));

    if (!documents.isEmpty())
        quickAccess->children.append(makeItem("Documents", "description", "quick", documents, false, false, quickAccess));

    if (!pictures.isEmpty())
        quickAccess->children.append(makeItem("Pictures", "image", "quick", pictures, false, false, quickAccess));

    if (!music.isEmpty())
        quickAccess->children.append(makeItem("Music", "music-note", "quick", music, false, false, quickAccess));

    if (!videos.isEmpty())
        quickAccess->children.append(makeItem("Videos", "movie", "quick", videos, false, false, quickAccess));

    endResetModel();
}