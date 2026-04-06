#include "workspace/FileListModel.h"

FileListModel::FileListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int FileListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return static_cast<int>(m_items.size());
}

QVariant FileListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid())
        return {};

    const int row = index.row();
    if (row < 0 || row >= m_items.size())
        return {};

    const FileItem& item = m_items.at(row);

    switch (role)
    {
    case Qt::DisplayRole:
    case NameRole:
        return item.name;
    case PathRole:
        return item.path;
    case DateModifiedRole:
        return item.dateModified;
    case TypeRole:
        return item.type;
    case SizeRole:
        return item.size;
    case IconRole:
        return item.icon;
    case IsDirRole:
        return item.isDir;
    default:
        return {};
    }
}

QHash<int, QByteArray> FileListModel::roleNames() const
{
    return {
        { NameRole, "name" },
        { PathRole, "path" },
        { DateModifiedRole, "dateModified" },
        { TypeRole, "type" },
        { SizeRole, "size" },
        { IconRole, "icon" },
        { IsDirRole, "isDir" }
    };
}

void FileListModel::setItems(const QVector<FileItem>& items)
{
    beginResetModel();
    m_items = items;
    endResetModel();
}

QVector<FileListModel::FileItem> FileListModel::items() const
{
    return m_items;
}

bool FileListModel::insertItem(int row, const FileItem& item)
{
    if (row < 0)
        row = 0;
    if (row > m_items.size())
        row = m_items.size();

    beginInsertRows(QModelIndex(), row, row);
    m_items.insert(row, item);
    endInsertRows();
    return true;
}

bool FileListModel::removeItem(int row)
{
    if (row < 0 || row >= m_items.size())
        return false;

    beginRemoveRows(QModelIndex(), row, row);
    m_items.removeAt(row);
    endRemoveRows();
    return true;
}

bool FileListModel::updateItem(int row, const FileItem& item)
{
    if (row < 0 || row >= m_items.size())
        return false;

    m_items[row] = item;
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(
        modelIndex,
        modelIndex,
        { NameRole, PathRole, DateModifiedRole, TypeRole, SizeRole, IconRole, IsDirRole });

    return true;
}

QVariantMap FileListModel::get(int row) const
{
    if (row < 0 || row >= m_items.size())
        return {};

    const FileItem& item = m_items.at(row);

    QVariantMap map;
    map.insert(QStringLiteral("name"), item.name);
    map.insert(QStringLiteral("path"), item.path);
    map.insert(QStringLiteral("dateModified"), item.dateModified);
    map.insert(QStringLiteral("type"), item.type);
    map.insert(QStringLiteral("size"), item.size);
    map.insert(QStringLiteral("icon"), item.icon);
    map.insert(QStringLiteral("isDir"), item.isDir);
    return map;
}