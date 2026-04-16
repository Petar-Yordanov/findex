#include "QuickAccessModel.h"

#include <QDir>
#include <QSet>
#include <QStandardPaths>

QuickAccessModel::QuickAccessModel(QObject* parent)
    : QAbstractListModel(parent)
{
    loadDefaults();
}

int QuickAccessModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_items.size();
}

QVariant QuickAccessModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const auto& item = m_items.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
    case LabelRole:
        return item.label;
    case PathRole:
        return item.path;
    case IconRole:
        return item.icon;
    case KindRole:
        return item.kind;
    default:
        return {};
    }
}

QHash<int, QByteArray> QuickAccessModel::roleNames() const
{
    return {
        { LabelRole, "label" },
        { PathRole, "path" },
        { IconRole, "icon" },
        { KindRole, "kind" }
    };
}

void QuickAccessModel::loadDefaults()
{
    beginResetModel();

    m_items.clear();

    auto norm = [](const QString& p) -> QString {
        return p.trimmed().isEmpty() ? QString() : QDir::fromNativeSeparators(QDir(p).absolutePath());
    };

    auto appendItem = [this](QSet<QString>& seen,
                             const QString& label,
                             const QString& icon,
                             const QString& kind,
                             const QString& path) {
        const QString normalizedPath = path.trimmed();
        if (normalizedPath.isEmpty())
            return;

        const QString dedupeKey = kind + QStringLiteral("::") + normalizedPath.toLower();
        if (seen.contains(dedupeKey))
            return;

        seen.insert(dedupeKey);
        m_items.push_back({ label, normalizedPath, icon, kind });
    };

    QSet<QString> seen;

#ifdef Q_OS_WINDOWS
    appendItem(
        seen,
        QStringLiteral("Recent"),
        QStringLiteral("history"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
             + QStringLiteral("/AppData/Roaming/Microsoft/Windows/Recent")));
#endif

    appendItem(seen, QStringLiteral("Home"), QStringLiteral("home"), QStringLiteral("quick"), norm(QDir::homePath()));
    appendItem(
        seen,
        QStringLiteral("Desktop"),
        QStringLiteral("desktop-windows"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation)));
    appendItem(
        seen,
        QStringLiteral("Downloads"),
        QStringLiteral("download"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)));
    appendItem(
        seen,
        QStringLiteral("Documents"),
        QStringLiteral("description"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)));
    appendItem(
        seen,
        QStringLiteral("Pictures"),
        QStringLiteral("image"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::PicturesLocation)));
    appendItem(
        seen,
        QStringLiteral("Music"),
        QStringLiteral("music-note"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::MusicLocation)));
    appendItem(
        seen,
        QStringLiteral("Videos"),
        QStringLiteral("movie"),
        QStringLiteral("quick"),
        norm(QStandardPaths::writableLocation(QStandardPaths::MoviesLocation)));

    endResetModel();
}
