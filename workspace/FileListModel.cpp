#include "workspace/FileListModel.h"

FileListModel::FileListModel(QObject* parent)
    : QAbstractListModel(parent)
{
    loadDefaults();
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

QVariantMap FileListModel::get(int row) const
{
    if (row < 0 || row >= m_items.size())
        return {};

    const FileItem& item = m_items.at(row);

    QVariantMap map;
    map.insert(QStringLiteral("name"), item.name);
    map.insert(QStringLiteral("dateModified"), item.dateModified);
    map.insert(QStringLiteral("type"), item.type);
    map.insert(QStringLiteral("size"), item.size);
    map.insert(QStringLiteral("icon"), item.icon);
    map.insert(QStringLiteral("isDir"), item.isDir);
    return map;
}

void FileListModel::loadDefaults()
{
    setItems({
        { QStringLiteral("Backup"), QStringLiteral("13/02/2026 12:01"), QStringLiteral("File folder"), QString(), QStringLiteral("folder"), true },
        { QStringLiteral("Games"), QStringLiteral("06/03/2026 21:58"), QStringLiteral("File folder"), QString(), QStringLiteral("folder"), true },
        { QStringLiteral("inetpub"), QStringLiteral("07/02/2026 22:34"), QStringLiteral("File folder"), QString(), QStringLiteral("folder"), true },
        { QStringLiteral("Program Files"), QStringLiteral("06/03/2026 22:07"), QStringLiteral("File folder"), QString(), QStringLiteral("folder"), true },
        { QStringLiteral("appverifUI.dll"), QStringLiteral("12/11/2025 15:27"), QStringLiteral("Application extension"), QStringLiteral("110 KB"), QStringLiteral("insert-drive-file"), false },
        { QStringLiteral("chrome.exe"), QStringLiteral("03/03/2026 09:14"), QStringLiteral("Application"), QStringLiteral("248 MB"), QStringLiteral("insert-drive-file"), false },
        { QStringLiteral("readme.txt"), QStringLiteral("28/02/2026 18:42"), QStringLiteral("Text Document"), QStringLiteral("4 KB"), QStringLiteral("description"), false },
        { QStringLiteral("meeting-notes.docx"), QStringLiteral("10/03/2026 11:05"), QStringLiteral("Microsoft Word Document"), QStringLiteral("86 KB"), QStringLiteral("description"), false },
        { QStringLiteral("budget-2026.xlsx"), QStringLiteral("14/03/2026 08:51"), QStringLiteral("Microsoft Excel Worksheet"), QStringLiteral("214 KB"), QStringLiteral("description"), false },
        { QStringLiteral("presentation-q1.pptx"), QStringLiteral("07/03/2026 16:23"), QStringLiteral("Microsoft PowerPoint Presentation"), QStringLiteral("3.8 MB"), QStringLiteral("description"), false },
        { QStringLiteral("invoice-1482.pdf"), QStringLiteral("01/03/2026 13:37"), QStringLiteral("PDF Document"), QStringLiteral("512 KB"), QStringLiteral("picture-as-pdf"), false },
        { QStringLiteral("hero-banner.png"), QStringLiteral("11/03/2026 20:16"), QStringLiteral("PNG File"), QStringLiteral("1.9 MB"), QStringLiteral("image"), false },
        { QStringLiteral("vacation-photo.jpg"), QStringLiteral("22/02/2026 17:08"), QStringLiteral("JPEG Image"), QStringLiteral("4.6 MB"), QStringLiteral("image"), false },
        { QStringLiteral("logo-final.svg"), QStringLiteral("09/03/2026 10:44"), QStringLiteral("SVG Document"), QStringLiteral("72 KB"), QStringLiteral("image"), false },
        { QStringLiteral("theme-song.mp3"), QStringLiteral("18/01/2026 21:55"), QStringLiteral("MP3 File"), QStringLiteral("8.7 MB"), QStringLiteral("music-note"), false },
        { QStringLiteral("launch-trailer.mp4"), QStringLiteral("13/03/2026 22:11"), QStringLiteral("MP4 Video"), QStringLiteral("148 MB"), QStringLiteral("movie"), false },
        { QStringLiteral("archive-backup.zip"), QStringLiteral("05/03/2026 07:30"), QStringLiteral("Compressed (zipped) Folder"), QStringLiteral("640 MB"), QStringLiteral("zip"), false },
        { QStringLiteral("logs.7z"), QStringLiteral("27/02/2026 23:03"), QStringLiteral("7-Zip Archive"), QStringLiteral("92 MB"), QStringLiteral("zip"), false },
        { QStringLiteral("installer.msi"), QStringLiteral("16/02/2026 14:29"), QStringLiteral("Windows Installer Package"), QStringLiteral("27 MB"), QStringLiteral("insert-drive-file"), false },
        { QStringLiteral("config.json"), QStringLiteral("12/03/2026 09:57"), QStringLiteral("JSON Source File"), QStringLiteral("12 KB"), QStringLiteral("code"), false },
        { QStringLiteral("settings.yaml"), QStringLiteral("11/03/2026 08:40"), QStringLiteral("YAML Document"), QStringLiteral("6 KB"), QStringLiteral("code"), false },
        { QStringLiteral("main.cpp"), QStringLiteral("14/03/2026 10:32"), QStringLiteral("C++ Source File"), QStringLiteral("34 KB"), QStringLiteral("code"), false },
        { QStringLiteral("mainwindow.qml"), QStringLiteral("14/03/2026 10:48"), QStringLiteral("QML File"), QStringLiteral("58 KB"), QStringLiteral("code"), false },
        { QStringLiteral("script.ps1"), QStringLiteral("06/03/2026 12:19"), QStringLiteral("PowerShell Script"), QStringLiteral("9 KB"), QStringLiteral("terminal"), false },
        { QStringLiteral("run.bat"), QStringLiteral("20/02/2026 19:11"), QStringLiteral("Windows Batch File"), QStringLiteral("2 KB"), QStringLiteral("terminal"), false }
    });
}