#include "FileManagerFileOpsService.h"

#include <algorithm>

FileManagerFileOpsService::FileManagerFileOpsService(QObject* parent)
    : QObject(parent)
{
    reloadForPath(QStringLiteral("C:/Projects/Qt"));
}

QVariantMap FileManagerFileOpsService::makeFile(const QString& name,
                                                const QString& dateModified,
                                                const QString& type,
                                                const QString& size,
                                                const QString& icon) const
{
    return QVariantMap{
        {"name", name},
        {"dateModified", dateModified},
        {"type", type},
        {"size", size},
        {"icon", icon}
    };
}

QVariantList FileManagerFileOpsService::files() const
{
    return m_files;
}

QVariantMap FileManagerFileOpsService::fileAt(int row) const
{
    if (row < 0 || row >= m_files.size())
        return {};

    return m_files[row].toMap();
}

void FileManagerFileOpsService::reloadForPath(const QString& pathText)
{
    Q_UNUSED(pathText);

    m_files = {
        makeFile("Backup", "13/02/2026 12:01", "File folder", "", "folder"),
        makeFile("Games", "06/03/2026 21:58", "File folder", "", "folder"),
        makeFile("Program Files", "06/03/2026 22:07", "File folder", "", "folder"),
        makeFile("readme.txt", "28/02/2026 18:42", "Text Document", "4 KB", "description"),
        makeFile("chrome.exe", "03/03/2026 09:14", "Application", "248 MB", "insert-drive-file"),
        makeFile("invoice-1482.pdf", "01/03/2026 13:37", "PDF Document", "512 KB", "picture-as-pdf"),
        makeFile("hero-banner.png", "11/03/2026 20:16", "PNG File", "1.9 MB", "image"),
        makeFile("theme-song.mp3", "18/01/2026 21:55", "MP3 File", "8.7 MB", "music-note"),
        makeFile("launch-trailer.mp4", "13/03/2026 22:11", "MP4 Video", "148 MB", "movie"),
        makeFile("archive-backup.zip", "05/03/2026 07:30", "Compressed (zipped) Folder", "640 MB", "zip")
    };
}

void FileManagerFileOpsService::createFile()
{
    m_files.insert(0, makeFile("New file.txt", "17/03/2026 12:00", "Text Document", "0 KB", "description"));
}

void FileManagerFileOpsService::createFolder()
{
    m_files.insert(0, makeFile("New folder", "17/03/2026 12:00", "File folder", "", "folder"));
}

void FileManagerFileOpsService::renameRow(int row, const QString& newName)
{
    if (row < 0 || row >= m_files.size())
        return;

    QVariantMap file = m_files[row].toMap();
    if (!newName.trimmed().isEmpty()) {
        file["name"] = newName.trimmed();
        m_files[row] = file;
    }
}

void FileManagerFileOpsService::deleteRow(int row)
{
    if (row < 0 || row >= m_files.size())
        return;

    m_files.removeAt(row);
}

void FileManagerFileOpsService::deleteRows(const QVariantList& rows)
{
    QList<int> indices;
    for (const auto& row : rows)
        indices.push_back(row.toInt());

    std::sort(indices.begin(), indices.end(), std::greater<int>());

    for (int index : indices) {
        if (index >= 0 && index < m_files.size())
            m_files.removeAt(index);
    }
}

void FileManagerFileOpsService::moveRows(const QVariantList& rows,
                                         const QString& targetLabel,
                                         const QString& targetKind)
{
    Q_UNUSED(rows);
    Q_UNUSED(targetLabel);
    Q_UNUSED(targetKind);
}