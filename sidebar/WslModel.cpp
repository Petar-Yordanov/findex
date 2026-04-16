#include "WslModel.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>

#ifdef Q_OS_WINDOWS
#include <QProcess>
#endif

WslModel::WslModel(QObject* parent)
    : QAbstractItemModel(parent)
    , m_root(new SidebarTreeItem)
{
    loadDefaults();
}

WslModel::~WslModel()
{
    delete m_root;
    m_root = nullptr;
}

SidebarTreeItem* WslModel::makeItem(
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

SidebarTreeItem* WslModel::itemFromIndex(const QModelIndex& index) const
{
    if (index.isValid())
        return static_cast<SidebarTreeItem*>(index.internalPointer());

    return m_root;
}

QModelIndex WslModel::index(int row, int column, const QModelIndex& parentIndex) const
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

QModelIndex WslModel::parent(const QModelIndex& child) const
{
    if (!child.isValid())
        return {};

    auto* childItem = static_cast<SidebarTreeItem*>(child.internalPointer());
    if (!childItem || !childItem->parent || childItem->parent == m_root)
        return {};

    SidebarTreeItem* parentItem = childItem->parent;
    return createIndex(parentItem->rowInParent(), 0, parentItem);
}

int WslModel::rowCount(const QModelIndex& parentIndex) const
{
    if (parentIndex.isValid() && parentIndex.column() != 0)
        return 0;

    SidebarTreeItem* parentItem = itemFromIndex(parentIndex);
    return parentItem ? parentItem->children.size() : 0;
}

int WslModel::columnCount(const QModelIndex&) const
{
    return 1;
}

QVariant WslModel::data(const QModelIndex& index, int role) const
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

QHash<int, QByteArray> WslModel::roleNames() const
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

QString WslModel::label(const QModelIndex& index) const
{
    return data(index, LabelRole).toString();
}

QString WslModel::icon(const QModelIndex& index) const
{
    return data(index, IconRole).toString();
}

QString WslModel::kind(const QModelIndex& index) const
{
    return data(index, KindRole).toString();
}

QString WslModel::path(const QModelIndex& index) const
{
    return data(index, PathRole).toString();
}

bool WslModel::section(const QModelIndex& index) const
{
    return data(index, SectionRole).toBool();
}

bool WslModel::expandedByDefault(const QModelIndex& index) const
{
    return data(index, ExpandedByDefaultRole).toBool();
}

bool WslModel::hasChildrenAt(const QModelIndex& index) const
{
    return data(index, HasChildrenRole).toBool();
}

void WslModel::loadDefaults()
{
    beginResetModel();

    qDeleteAll(m_root->children);
    m_root->children.clear();

    auto norm = [](const QString& p) -> QString {
        return QDir::fromNativeSeparators(QDir(p).absolutePath());
    };

#ifdef Q_OS_WINDOWS
    {
        auto decodeWslOutput = [](const QByteArray& bytes) -> QString {
            if (bytes.isEmpty())
                return {};

            if (bytes.size() >= 2) {
                const uchar b0 = static_cast<uchar>(bytes.at(0));
                const uchar b1 = static_cast<uchar>(bytes.at(1));

                if ((b0 == 0xFF && b1 == 0xFE) || (b0 == 0xFE && b1 == 0xFF)) {
                    const QString utf16 = QString::fromUtf16(
                        reinterpret_cast<const char16_t*>(bytes.constData() + 2),
                        (bytes.size() - 2) / 2);
                    return utf16;
                }
            }

            int zeroCount = 0;
            const int probeLen = qMin(bytes.size(), 64);
            for (int i = 1; i < probeLen; i += 2) {
                if (bytes.at(i) == '\0')
                    ++zeroCount;
            }

            if (zeroCount >= qMax(4, probeLen / 8)) {
                return QString::fromUtf16(
                    reinterpret_cast<const char16_t*>(bytes.constData()),
                    bytes.size() / 2);
            }

            return QString::fromLocal8Bit(bytes);
        };

        QProcess wsl;
        wsl.start(QStringLiteral("wsl.exe"), { QStringLiteral("-l"), QStringLiteral("-q") });
        wsl.waitForFinished(3000);

        const QString stdoutText = decodeWslOutput(wsl.readAllStandardOutput());
        const QStringList rawLines = stdoutText.split(
            QRegularExpression(QStringLiteral("[\r\n]")),
            Qt::SkipEmptyParts);

        QStringList distros;
        for (QString line : rawLines) {
            line = line.trimmed();
            if (line.isEmpty())
                continue;

            if (line.startsWith(QStringLiteral("Windows Subsystem for Linux Distributions"),
                                Qt::CaseInsensitive)) {
                continue;
            }

            if (!distros.contains(line, Qt::CaseInsensitive))
                distros.push_back(line);
        }

        for (const QString& distro : std::as_const(distros)) {
            QString distroPath = QStringLiteral("//wsl.localhost/%1").arg(distro);
            if (!QFileInfo::exists(distroPath))
                distroPath = QStringLiteral("//wsl$/%1").arg(distro);

            auto* distroItem = makeItem(
                distro,
                "folder",
                "wsl",
                norm(distroPath),
                false,
                false,
                m_root);

            const QStringList commonDirs = {
                QStringLiteral("home"),
                QStringLiteral("root"),
                QStringLiteral("mnt"),
                QStringLiteral("usr"),
                QStringLiteral("etc"),
                QStringLiteral("var"),
                QStringLiteral("tmp")
            };

            for (const QString& dirName : commonDirs) {
                const QString childPath = QDir(distroPath).filePath(dirName);
                QFileInfo childInfo(childPath);
                if (!childInfo.exists() || !childInfo.isDir())
                    continue;

                distroItem->children.append(makeItem(
                    dirName,
                    "folder",
                    "wsl",
                    QDir::fromNativeSeparators(childInfo.absoluteFilePath()),
                    false,
                    false,
                    distroItem));
            }

            m_root->children.append(distroItem);
        }
    }
#endif

    endResetModel();
}
