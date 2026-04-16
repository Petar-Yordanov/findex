#include "FileOperationWorker.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>

namespace
{
constexpr qint64 kCopyChunkSize = 1024 * 1024;
}

FileOperationWorker::FileOperationWorker(QObject* parent)
    : QObject(parent)
{
}

void FileOperationWorker::configure(Mode mode,
                                    const QStringList& sourcePaths,
                                    const QString& destinationDirectory)
{
    m_mode = mode;
    m_sourcePaths = sourcePaths;
    m_destinationDirectory = destinationDirectory;
}

void FileOperationWorker::run()
{
    if (m_sourcePaths.isEmpty()) {
        emit failed(QStringLiteral("No items to process."));
        emit finished();
        return;
    }

    switch (m_mode)
    {
    case Mode::Copy:
    case Mode::Move:
        runCopyOrMove();
        break;
    case Mode::Delete:
        runDelete();
        break;
    }

    emit finished();
}

void FileOperationWorker::runCopyOrMove()
{
    ProgressState state;
    state.totalBytes = computeTotalBytes(m_sourcePaths);
    state.title = (m_mode == Mode::Copy)
                      ? QStringLiteral("Copying items")
                      : QStringLiteral("Moving items");

    if (state.totalBytes <= 0)
        state.totalBytes = 1;

    int successCount = 0;

    for (const QString& sourcePath : m_sourcePaths)
    {
        QFileInfo srcInfo(sourcePath);
        if (!srcInfo.exists())
            continue;

        const QString destinationPath =
            uniquePathInDirectory(m_destinationDirectory, srcInfo.fileName());

        const bool ok = processCopyPath(
            sourcePath,
            destinationPath,
            m_mode == Mode::Move,
            state);

        if (!ok) {
            emit failed(QStringLiteral("%1 failed for %2")
                            .arg(m_mode == Mode::Copy ? QStringLiteral("Copy") : QStringLiteral("Move"),
                                 srcInfo.fileName()));
            return;
        }

        ++successCount;
    }

    emitProgress(state, true);

    if (successCount > 0) {
        emit completed(QStringLiteral("%1 %2 item(s)")
                           .arg(m_mode == Mode::Copy ? QStringLiteral("Copied") : QStringLiteral("Moved"))
                           .arg(successCount));
    } else {
        emit failed(QStringLiteral("%1 failed.")
                        .arg(m_mode == Mode::Copy ? QStringLiteral("Copy") : QStringLiteral("Move")));
    }
}

void FileOperationWorker::runDelete()
{
    ProgressState state;
    state.totalBytes = computeTotalBytes(m_sourcePaths);
    state.title = QStringLiteral("Deleting items");

    if (state.totalBytes <= 0)
        state.totalBytes = 1;

    int deletedCount = 0;

    for (const QString& path : m_sourcePaths)
    {
        QFileInfo info(path);
        if (!info.exists())
            continue;

        if (!deletePathRecursive(path, state)) {
            emit failed(QStringLiteral("Delete failed for %1").arg(info.fileName()));
            return;
        }

        ++deletedCount;
    }

    emitProgress(state, true);

    if (deletedCount > 0)
        emit completed(QStringLiteral("Deleted %1 item(s)").arg(deletedCount));
    else
        emit failed(QStringLiteral("Delete failed."));
}

bool FileOperationWorker::processCopyPath(const QString& sourcePath,
                                          const QString& destinationPath,
                                          bool removeSourceAfterCopy,
                                          ProgressState& state)
{
    QFileInfo sourceInfo(sourcePath);
    if (!sourceInfo.exists())
        return false;

    if (removeSourceAfterCopy) {
        QFileInfo destinationInfo(destinationPath);
        if (QFile::rename(sourcePath, destinationPath)) {
            state.handledBytes += computePathBytes(destinationPath);
            emitProgress(state, false);
            return true;
        }

        if (destinationInfo.exists())
            return false;
    }

    if (sourceInfo.isDir()) {
        return copyDirectoryRecursive(sourcePath, destinationPath, removeSourceAfterCopy, state);
    }

    if (!copyFileWithProgress(sourcePath, destinationPath, state))
        return false;

    if (removeSourceAfterCopy && !QFile::remove(sourcePath))
        return false;

    return true;
}

bool FileOperationWorker::copyDirectoryRecursive(const QString& sourceDirPath,
                                                 const QString& destinationDirPath,
                                                 bool removeSourceAfterCopy,
                                                 ProgressState& state)
{
    QDir destDir;
    if (!destDir.mkpath(destinationDirPath))
        return false;

    QDir srcDir(sourceDirPath);
    const QFileInfoList entries = srcDir.entryInfoList(
        QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);

    for (const QFileInfo& entry : entries)
    {
        const QString nextSource = entry.absoluteFilePath();
        const QString nextDestination = QDir(destinationDirPath).filePath(entry.fileName());

        if (entry.isDir()) {
            if (!copyDirectoryRecursive(nextSource, nextDestination, removeSourceAfterCopy, state))
                return false;
        } else {
            if (!copyFileWithProgress(nextSource, nextDestination, state))
                return false;

            if (removeSourceAfterCopy && !QFile::remove(nextSource))
                return false;
        }
    }

    if (removeSourceAfterCopy) {
        QDir sourceDir(sourceDirPath);
        if (!sourceDir.rmdir(sourceDirPath))
            return false;
    }

    return true;
}

bool FileOperationWorker::copyFileWithProgress(const QString& sourceFilePath,
                                               const QString& destinationFilePath,
                                               ProgressState& state)
{
    QFile sourceFile(sourceFilePath);
    if (!sourceFile.open(QIODevice::ReadOnly))
        return false;

    QFileInfo destinationInfo(destinationFilePath);
    QDir().mkpath(destinationInfo.dir().absolutePath());

    QFile::remove(destinationFilePath);

    QFile destinationFile(destinationFilePath);
    if (!destinationFile.open(QIODevice::WriteOnly))
        return false;

    while (!sourceFile.atEnd())
    {
        const QByteArray chunk = sourceFile.read(kCopyChunkSize);
        if (chunk.isEmpty() && sourceFile.error() != QFileDevice::NoError)
            return false;

        const qint64 written = destinationFile.write(chunk);
        if (written != chunk.size())
            return false;

        state.handledBytes += written;
        emitProgress(state, false);
    }

    destinationFile.flush();
    destinationFile.close();
    sourceFile.close();

    return true;
}

bool FileOperationWorker::deletePathRecursive(const QString& path, ProgressState& state)
{
    QFileInfo info(path);
    if (!info.exists())
        return true;

    if (info.isDir()) {
        QDir dir(path);
        const QFileInfoList entries = dir.entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);

        for (const QFileInfo& entry : entries) {
            if (!deletePathRecursive(entry.absoluteFilePath(), state))
                return false;
        }

        QDir parentDir = info.dir();
        return parentDir.rmdir(info.fileName());
    }

    const qint64 fileBytes = info.size();
    if (!QFile::remove(path))
        return false;

    state.handledBytes += qMax<qint64>(0, fileBytes);
    emitProgress(state, false);
    return true;
}

qint64 FileOperationWorker::computeTotalBytes(const QStringList& paths) const
{
    qint64 total = 0;
    for (const QString& path : paths)
        total += computePathBytes(path);
    return total;
}

qint64 FileOperationWorker::computePathBytes(const QString& path) const
{
    QFileInfo info(path);
    if (!info.exists())
        return 0;

    if (info.isFile())
        return qMax<qint64>(0, info.size());

    qint64 total = 0;
    QDirIterator it(path,
                    QDir::Files | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System,
                    QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        total += qMax<qint64>(0, it.fileInfo().size());
    }

    return total;
}

QString FileOperationWorker::uniquePathInDirectory(const QString& directoryPath,
                                                   const QString& originalName) const
{
    QDir dir(directoryPath);
    QString candidate = originalName;
    QFileInfo baseInfo(originalName);

    const QString completeBaseName = baseInfo.completeBaseName();
    const QString suffix = baseInfo.suffix();

    int counter = 1;
    while (dir.exists(candidate)) {
        if (suffix.isEmpty())
            candidate = QStringLiteral("%1 (%2)").arg(originalName).arg(counter);
        else
            candidate = QStringLiteral("%1 (%2).%3").arg(completeBaseName).arg(counter).arg(suffix);
        ++counter;
    }

    return dir.filePath(candidate);
}

void FileOperationWorker::emitProgress(ProgressState& state, bool done)
{
    const qint64 boundedTotal = qMax<qint64>(1, state.totalBytes);
    const qint64 boundedHandled = qBound<qint64>(0, state.handledBytes, boundedTotal);
    const int percent = done ? 100 : static_cast<int>((boundedHandled * 100) / boundedTotal);

    const QString details = QStringLiteral("%1 of %2 handled")
                                .arg(formatBytes(boundedHandled), formatBytes(boundedTotal));

    emit progress(state.title, details, percent, done);
}

QString FileOperationWorker::formatBytes(qint64 bytes)
{
    static const double kb = 1024.0;
    static const double mb = kb * 1024.0;
    static const double gb = mb * 1024.0;
    static const double tb = gb * 1024.0;

    const double value = static_cast<double>(bytes);

    if (value >= tb)
        return QString::number(value / tb, 'f', 2) + QStringLiteral(" TB");
    if (value >= gb)
        return QString::number(value / gb, 'f', 2) + QStringLiteral(" GB");
    if (value >= mb)
        return QString::number(value / mb, 'f', 1) + QStringLiteral(" MB");
    if (value >= kb)
        return QString::number(value / kb, 'f', 1) + QStringLiteral(" KB");
    return QString::number(bytes) + QStringLiteral(" B");
}