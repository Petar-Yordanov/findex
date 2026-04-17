#include "workspace/WorkspaceViewModel.h"

#include "FileAssociationService.h"

#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QGuiApplication>
#include <QLocale>
#include <QMetaObject>
#include <QMimeDatabase>
#include <QMimeData>
#include <QMimeType>
#include <QPointer>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QVariantList>
#include <QUrl>
#include <QtConcurrent>
#include <QElapsedTimer>
#include <algorithm>

#include <Qt>

namespace
{
QString formatBytes(qint64 bytes)
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

bool isWindowsShortcutLikeSuffix(const QString& suffix)
{
    const QString lower = suffix.toLower();
    return lower == QStringLiteral("url") || lower == QStringLiteral("lnk");
}

QString displayNameForFileInfo(const QFileInfo& info)
{
    if (info.isDir())
        return info.fileName();

#ifdef Q_OS_WINDOWS
    if (isWindowsShortcutLikeSuffix(info.suffix()))
        return info.completeBaseName();
#endif

    return info.fileName();
}

QString iconForFileInfo(const QFileInfo& info)
{
    if (info.isDir())
        return QStringLiteral("folder");

    const QString suffix = info.suffix().toLower();

#ifdef Q_OS_WINDOWS
    if (suffix == QStringLiteral("url") || suffix == QStringLiteral("lnk"))
        return QStringLiteral("launch");
#endif

    if (suffix == QStringLiteral("txt") || suffix == QStringLiteral("md")
        || suffix == QStringLiteral("rst") || suffix == QStringLiteral("doc")
        || suffix == QStringLiteral("docx"))
        return QStringLiteral("description");

    if (suffix == QStringLiteral("pdf"))
        return QStringLiteral("picture-as-pdf");

    if (suffix == QStringLiteral("png") || suffix == QStringLiteral("jpg")
        || suffix == QStringLiteral("jpeg") || suffix == QStringLiteral("svg")
        || suffix == QStringLiteral("gif") || suffix == QStringLiteral("webp")
        || suffix == QStringLiteral("bmp") || suffix == QStringLiteral("ico") || suffix == QStringLiteral("webp"))
        return QStringLiteral("image");

    if (suffix == QStringLiteral("mp3") || suffix == QStringLiteral("wav")
        || suffix == QStringLiteral("flac") || suffix == QStringLiteral("ogg")
        || suffix == QStringLiteral("m4a"))
        return QStringLiteral("music-note");

    if (suffix == QStringLiteral("mp4") || suffix == QStringLiteral("mkv")
        || suffix == QStringLiteral("avi") || suffix == QStringLiteral("mov")
        || suffix == QStringLiteral("wmv") || suffix == QStringLiteral("webm"))
        return QStringLiteral("movie");

    if (suffix == QStringLiteral("zip") || suffix == QStringLiteral("7z")
        || suffix == QStringLiteral("rar") || suffix == QStringLiteral("tar")
        || suffix == QStringLiteral("gz") || suffix == QStringLiteral("bz2")
        || suffix == QStringLiteral("xz"))
        return QStringLiteral("zip");

    if (suffix == QStringLiteral("ps1") || suffix == QStringLiteral("bat")
        || suffix == QStringLiteral("cmd") || suffix == QStringLiteral("sh")
        || suffix == QStringLiteral("bash") || suffix == QStringLiteral("zsh")
        || suffix == QStringLiteral("fish"))
        return QStringLiteral("terminal");

    if (suffix == QStringLiteral("exe") || suffix == QStringLiteral("msi"))
        return QStringLiteral("launch");

    if (suffix == QStringLiteral("torrent"))
        return QStringLiteral("download");

    if (suffix == QStringLiteral("c") || suffix == QStringLiteral("h")
        || suffix == QStringLiteral("cpp") || suffix == QStringLiteral("cxx")
        || suffix == QStringLiteral("cc") || suffix == QStringLiteral("hpp")
        || suffix == QStringLiteral("hh") || suffix == QStringLiteral("hxx")
        || suffix == QStringLiteral("cs") || suffix == QStringLiteral("java")
        || suffix == QStringLiteral("kt") || suffix == QStringLiteral("kts")
        || suffix == QStringLiteral("swift") || suffix == QStringLiteral("go")
        || suffix == QStringLiteral("rs") || suffix == QStringLiteral("py")
        || suffix == QStringLiteral("rb") || suffix == QStringLiteral("php")
        || suffix == QStringLiteral("pl") || suffix == QStringLiteral("lua")
        || suffix == QStringLiteral("r") || suffix == QStringLiteral("m")
        || suffix == QStringLiteral("mm") || suffix == QStringLiteral("scala")
        || suffix == QStringLiteral("dart") || suffix == QStringLiteral("jl")
        || suffix == QStringLiteral("zig") || suffix == QStringLiteral("nim")
        || suffix == QStringLiteral("js") || suffix == QStringLiteral("mjs")
        || suffix == QStringLiteral("cjs") || suffix == QStringLiteral("ts")
        || suffix == QStringLiteral("tsx") || suffix == QStringLiteral("jsx")
        || suffix == QStringLiteral("qml") || suffix == QStringLiteral("json")
        || suffix == QStringLiteral("xml") || suffix == QStringLiteral("yaml")
        || suffix == QStringLiteral("yml") || suffix == QStringLiteral("toml")
        || suffix == QStringLiteral("ini") || suffix == QStringLiteral("conf")
        || suffix == QStringLiteral("cfg") || suffix == QStringLiteral("sql")
        || suffix == QStringLiteral("css") || suffix == QStringLiteral("scss")
        || suffix == QStringLiteral("sass") || suffix == QStringLiteral("less")
        || suffix == QStringLiteral("html") || suffix == QStringLiteral("htm")
        || suffix == QStringLiteral("vue") || suffix == QStringLiteral("svelte")
        || suffix == QStringLiteral("dockerfile"))
        return QStringLiteral("code");

    return QStringLiteral("insert-drive-file");
}

QString fallbackTypeFromSuffix(const QFileInfo& info)
{
    const QString suffix = info.suffix().toLower();

    if (suffix.isEmpty())
        return QStringLiteral("File");

#ifdef Q_OS_WINDOWS
    if (suffix == QStringLiteral("url"))
        return QStringLiteral("Internet Shortcut");
    if (suffix == QStringLiteral("lnk"))
        return QStringLiteral("Shortcut");
    if (suffix == QStringLiteral("exe"))
        return QStringLiteral("Application");
    if (suffix == QStringLiteral("msi"))
        return QStringLiteral("Windows Installer Package");
#endif

    if (suffix == QStringLiteral("txt"))
        return QStringLiteral("Text Document");
    if (suffix == QStringLiteral("md"))
        return QStringLiteral("Markdown Document");
    if (suffix == QStringLiteral("rst"))
        return QStringLiteral("reStructuredText Document");
    if (suffix == QStringLiteral("log"))
        return QStringLiteral("Log File");
    if (suffix == QStringLiteral("pdf"))
        return QStringLiteral("PDF Document");

    if (suffix == QStringLiteral("zip"))
        return QStringLiteral("Compressed Archive File");
    if (suffix == QStringLiteral("7z"))
        return QStringLiteral("7-Zip Archive");
    if (suffix == QStringLiteral("rar"))
        return QStringLiteral("RAR Archive");
    if (suffix == QStringLiteral("tar"))
        return QStringLiteral("TAR Archive");
    if (suffix == QStringLiteral("gz"))
        return QStringLiteral("GZip Archive");
    if (suffix == QStringLiteral("bz2"))
        return QStringLiteral("BZip2 Archive");
    if (suffix == QStringLiteral("xz"))
        return QStringLiteral("XZ Archive");
    if (suffix == QStringLiteral("torrent"))
        return QStringLiteral("Torrent File");

    if (suffix == QStringLiteral("png") || suffix == QStringLiteral("jpg")
        || suffix == QStringLiteral("jpeg") || suffix == QStringLiteral("gif")
        || suffix == QStringLiteral("webp") || suffix == QStringLiteral("svg")
        || suffix == QStringLiteral("bmp") || suffix == QStringLiteral("ico"))
        return QStringLiteral("Image File");

    if (suffix == QStringLiteral("mp3") || suffix == QStringLiteral("wav")
        || suffix == QStringLiteral("flac") || suffix == QStringLiteral("ogg")
        || suffix == QStringLiteral("m4a"))
        return QStringLiteral("Audio File");

    if (suffix == QStringLiteral("mp4") || suffix == QStringLiteral("mkv")
        || suffix == QStringLiteral("avi") || suffix == QStringLiteral("mov")
        || suffix == QStringLiteral("wmv") || suffix == QStringLiteral("webm"))
        return QStringLiteral("Video File");

    if (suffix == QStringLiteral("c"))
        return QStringLiteral("C Source File");
    if (suffix == QStringLiteral("h"))
        return QStringLiteral("C Header File");
    if (suffix == QStringLiteral("cpp") || suffix == QStringLiteral("cc")
        || suffix == QStringLiteral("cxx"))
        return QStringLiteral("C++ Source File");
    if (suffix == QStringLiteral("hpp") || suffix == QStringLiteral("hh")
        || suffix == QStringLiteral("hxx"))
        return QStringLiteral("C++ Header File");
    if (suffix == QStringLiteral("cs"))
        return QStringLiteral("C# Source File");
    if (suffix == QStringLiteral("java"))
        return QStringLiteral("Java Source File");
    if (suffix == QStringLiteral("kt") || suffix == QStringLiteral("kts"))
        return QStringLiteral("Kotlin Source File");
    if (suffix == QStringLiteral("swift"))
        return QStringLiteral("Swift Source File");
    if (suffix == QStringLiteral("go"))
        return QStringLiteral("Go Source File");
    if (suffix == QStringLiteral("rs"))
        return QStringLiteral("Rust Source File");
    if (suffix == QStringLiteral("py"))
        return QStringLiteral("Python Source File");
    if (suffix == QStringLiteral("rb"))
        return QStringLiteral("Ruby Source File");
    if (suffix == QStringLiteral("php"))
        return QStringLiteral("PHP Source File");
    if (suffix == QStringLiteral("pl"))
        return QStringLiteral("Perl Source File");
    if (suffix == QStringLiteral("lua"))
        return QStringLiteral("Lua Source File");
    if (suffix == QStringLiteral("r"))
        return QStringLiteral("R Source File");
    if (suffix == QStringLiteral("m"))
        return QStringLiteral("Objective-C Source File");
    if (suffix == QStringLiteral("mm"))
        return QStringLiteral("Objective-C++ Source File");
    if (suffix == QStringLiteral("scala"))
        return QStringLiteral("Scala Source File");
    if (suffix == QStringLiteral("dart"))
        return QStringLiteral("Dart Source File");
    if (suffix == QStringLiteral("jl"))
        return QStringLiteral("Julia Source File");
    if (suffix == QStringLiteral("zig"))
        return QStringLiteral("Zig Source File");
    if (suffix == QStringLiteral("nim"))
        return QStringLiteral("Nim Source File");

    if (suffix == QStringLiteral("js") || suffix == QStringLiteral("mjs")
        || suffix == QStringLiteral("cjs"))
        return QStringLiteral("JavaScript File");
    if (suffix == QStringLiteral("ts"))
        return QStringLiteral("TypeScript File");
    if (suffix == QStringLiteral("jsx"))
        return QStringLiteral("React JSX File");
    if (suffix == QStringLiteral("tsx"))
        return QStringLiteral("React TSX File");
    if (suffix == QStringLiteral("qml"))
        return QStringLiteral("QML File");
    if (suffix == QStringLiteral("json"))
        return QStringLiteral("JSON File");
    if (suffix == QStringLiteral("xml"))
        return QStringLiteral("XML File");
    if (suffix == QStringLiteral("yaml") || suffix == QStringLiteral("yml"))
        return QStringLiteral("YAML File");
    if (suffix == QStringLiteral("toml"))
        return QStringLiteral("TOML File");
    if (suffix == QStringLiteral("ini") || suffix == QStringLiteral("cfg")
        || suffix == QStringLiteral("conf"))
        return QStringLiteral("Configuration File");
    if (suffix == QStringLiteral("sql"))
        return QStringLiteral("SQL File");
    if (suffix == QStringLiteral("html") || suffix == QStringLiteral("htm"))
        return QStringLiteral("HTML Document");
    if (suffix == QStringLiteral("css"))
        return QStringLiteral("CSS File");
    if (suffix == QStringLiteral("scss"))
        return QStringLiteral("SCSS File");
    if (suffix == QStringLiteral("sass"))
        return QStringLiteral("Sass File");
    if (suffix == QStringLiteral("less"))
        return QStringLiteral("LESS File");
    if (suffix == QStringLiteral("vue"))
        return QStringLiteral("Vue Component");
    if (suffix == QStringLiteral("svelte"))
        return QStringLiteral("Svelte Component");
    if (suffix == QStringLiteral("sh"))
        return QStringLiteral("Shell Script");
    if (suffix == QStringLiteral("bash"))
        return QStringLiteral("Bash Script");
    if (suffix == QStringLiteral("zsh"))
        return QStringLiteral("Zsh Script");
    if (suffix == QStringLiteral("fish"))
        return QStringLiteral("Fish Script");
    if (suffix == QStringLiteral("bat"))
        return QStringLiteral("Batch File");
    if (suffix == QStringLiteral("cmd"))
        return QStringLiteral("Command Script");
    if (suffix == QStringLiteral("ps1"))
        return QStringLiteral("PowerShell Script");

    return QStringLiteral("%1 File").arg(suffix.toUpper());
}

bool looksLikeUselessMimeComment(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty())
        return true;

    const QString lower = trimmed.toLower();

    return lower == QStringLiteral("application/octet-stream")
           || lower == QStringLiteral("text/plain")
           || lower == QStringLiteral("application/x-msdownload")
           || lower == QStringLiteral("application/x-bittorrent")
           || lower == QStringLiteral("application/rls-services+xml")
           || lower.startsWith(QStringLiteral("application/"))
           || lower.startsWith(QStringLiteral("text/"));
}

QString typeForFileInfo(const QFileInfo& info)
{
    if (info.isDir())
        return QStringLiteral("File folder");

    const QString fallback = fallbackTypeFromSuffix(info);

    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile(info, QMimeDatabase::MatchContent);

    if (mime.isValid()) {
        const QString comment = mime.comment().trimmed();
        if (!looksLikeUselessMimeComment(comment))
            return comment;
    }

    return fallback;
}

bool shouldUseNativeIcon(const QFileInfo& info)
{
#ifdef Q_OS_MACOS
    if (info.isBundle())
        return true;
#endif

    if (info.isDir())
        return false;

    const QString suffix = info.suffix().toLower();

#ifdef Q_OS_WINDOWS
    if (suffix == QStringLiteral("exe")
        || suffix == QStringLiteral("msi")
        || suffix == QStringLiteral("lnk")
        || suffix == QStringLiteral("url")) {
        return true;
    }
#endif

#ifdef Q_OS_LINUX
    if (suffix == QStringLiteral("desktop"))
        return true;
#endif

#ifdef Q_OS_MACOS
    if (suffix == QStringLiteral("app"))
        return true;
#endif

    return false;
}

QString nativeIconSourceForFileInfo(const QFileInfo& info)
{
    if (!shouldUseNativeIcon(info))
        return {};

    return QStringLiteral("image://fileicons/%1")
        .arg(QString::fromLatin1(QUrl::toPercentEncoding(info.absoluteFilePath())));
}

int compareTextInsensitive(const QString& left, const QString& right)
{
    return QString::compare(left, right, Qt::CaseInsensitive);
}

int compareItemsByField(const FileListModel::FileItem& left,
                        const FileListModel::FileItem& right,
                        const QString& field)
{
    if (field == QStringLiteral("dateModified")) {
        if (left.lastModifiedValue < right.lastModifiedValue)
            return -1;
        if (left.lastModifiedValue > right.lastModifiedValue)
            return 1;
    } else if (field == QStringLiteral("type")) {
        const int typeCompare = compareTextInsensitive(left.type, right.type);
        if (typeCompare != 0)
            return typeCompare;
    } else if (field == QStringLiteral("size")) {
        if (left.sizeBytes < right.sizeBytes)
            return -1;
        if (left.sizeBytes > right.sizeBytes)
            return 1;
    }

    const int nameCompare = compareTextInsensitive(left.name, right.name);
    if (nameCompare != 0)
        return nameCompare;

    return compareTextInsensitive(left.path, right.path);
}

FileListModel::FileItem buildItemFromInfo(const QFileInfo& info)
{
    FileListModel::FileItem item;
    item.name = displayNameForFileInfo(info);
    item.path = QDir::fromNativeSeparators(info.absoluteFilePath());
    item.dateModified = info.lastModified().toString(QStringLiteral("dd/MM/yyyy HH:mm"));
    item.type = typeForFileInfo(info);
    item.size = info.isDir() ? QString() : formatBytes(info.size());
    item.icon = iconForFileInfo(info);
    item.nativeIconSource = nativeIconSourceForFileInfo(info);
    item.isDir = info.isDir();
    item.sizeBytes = info.isDir() ? 0 : qMax<qint64>(0, info.size());
    item.lastModifiedValue = info.lastModified();
    return item;
}

bool shouldIncludeInfo(const QFileInfo& info, bool showHidden)
{
    if (showHidden)
        return true;

    return !info.isHidden();
}

QString uniquePathInDirectory(const QString& directoryPath, const QString& originalName)
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

bool removeRecursively(const QString& path)
{
    QFileInfo info(path);
    if (!info.exists())
        return true;

    if (info.isDir()) {
        QDir dir(path);
        return dir.removeRecursively();
    }

    return QFile::remove(path);
}

bool isArchivePath(const QString& path)
{
    const QString lower = QFileInfo(path).suffix().toLower();
    return lower == QStringLiteral("zip")
           || lower == QStringLiteral("7z")
           || lower == QStringLiteral("rar")
           || lower == QStringLiteral("tar")
           || lower == QStringLiteral("gz");
}

QString quotePs(const QString& value)
{
    QString v = value;
    v.replace('\'', QStringLiteral("''"));
    return QStringLiteral("'") + v + QStringLiteral("'");
}

QString permissionsToString(QFileDevice::Permissions permissions)
{
    const auto bit = [permissions](QFileDevice::Permission permission, QChar enabled, QChar disabled) {
        return permissions.testFlag(permission) ? enabled : disabled;
    };

    QString result;
    result.reserve(9);
    result.append(bit(QFileDevice::ReadOwner, QLatin1Char('r'), QLatin1Char('-')));
    result.append(bit(QFileDevice::WriteOwner, QLatin1Char('w'), QLatin1Char('-')));
    result.append(bit(QFileDevice::ExeOwner, QLatin1Char('x'), QLatin1Char('-')));
    result.append(bit(QFileDevice::ReadGroup, QLatin1Char('r'), QLatin1Char('-')));
    result.append(bit(QFileDevice::WriteGroup, QLatin1Char('w'), QLatin1Char('-')));
    result.append(bit(QFileDevice::ExeGroup, QLatin1Char('x'), QLatin1Char('-')));
    result.append(bit(QFileDevice::ReadOther, QLatin1Char('r'), QLatin1Char('-')));
    result.append(bit(QFileDevice::WriteOther, QLatin1Char('w'), QLatin1Char('-')));
    result.append(bit(QFileDevice::ExeOther, QLatin1Char('x'), QLatin1Char('-')));
    return result;
}

qint64 totalBytesForPath(const QString& path)
{
    QFileInfo info(path);
    if (!info.exists())
        return 0;

    if (info.isFile())
        return qMax<qint64>(0, info.size());

    qint64 total = 0;
    QDirIterator it(
        path,
        QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System,
        QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        const QFileInfo current = it.fileInfo();
        if (current.isFile())
            total += qMax<qint64>(0, current.size());
    }

    return total;
}

struct AsyncOperationResult
{
    bool ok = false;
    int affectedCount = 0;
    QString successMessage;
    QString errorMessage;
};

class ProgressReporter
{
public:
    ProgressReporter() = default;

    ProgressReporter(QPointer<WorkspaceViewModel> target,
                     QString title,
                     qint64 totalBytes)
        : m_target(target)
        , m_title(std::move(title))
        , m_totalBytes(qMax<qint64>(1, totalBytes))
    {
        m_elapsed.start();
    }

    void advance(qint64 bytesHandledNow)
    {
        m_handledBytes += qMax<qint64>(0, bytesHandledNow);
        post(false);
    }

    void finish()
    {
        m_handledBytes = qMax(m_handledBytes, m_totalBytes);
        post(true);
    }

private:
    void post(bool done)
    {
        if (!m_target)
            return;

        const qint64 boundedHandled = qMin(m_handledBytes, m_totalBytes);
        const int progress = static_cast<int>(
            (100.0 * static_cast<double>(boundedHandled))
            / static_cast<double>(m_totalBytes));

        const bool percentChanged = (progress != m_lastProgress);
        const bool timeElapsedEnough = !m_elapsed.isValid() || m_elapsed.elapsed() >= 75;

        if (!done && !percentChanged && !timeElapsedEnough)
            return;

        m_lastProgress = progress;
        if (m_elapsed.isValid())
            m_elapsed.restart();

        const QString details = QStringLiteral("%1 of %2")
                                    .arg(formatBytes(boundedHandled),
                                         formatBytes(m_totalBytes));

        QMetaObject::invokeMethod(
            m_target.data(),
            [target = m_target, title = m_title, details, progress, done]() {
                if (!target)
                    return;
                emit target->operationProgress(title, details, progress, done);
            },
            Qt::QueuedConnection);
    }

    QPointer<WorkspaceViewModel> m_target;
    QString m_title;
    qint64 m_totalBytes = 1;
    qint64 m_handledBytes = 0;
    int m_lastProgress = -1;
    QElapsedTimer m_elapsed;
};

bool copyFileChunked(const QString& sourcePath,
                     const QString& destPath,
                     ProgressReporter& reporter,
                     QString* errorMessage)
{
    QFileInfo destInfo(destPath);
    QDir().mkpath(destInfo.dir().absolutePath());
    QFile::remove(destPath);

    QFile source(sourcePath);
    if (!source.open(QIODevice::ReadOnly)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Failed to open source file: %1").arg(sourcePath);
        return false;
    }

    QFile dest(destPath);
    if (!dest.open(QIODevice::WriteOnly)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Failed to create destination file: %1").arg(destPath);
        return false;
    }

    constexpr qint64 chunkSize = 1024 * 1024;
    while (!source.atEnd()) {
        const QByteArray chunk = source.read(chunkSize);
        if (chunk.isEmpty() && source.error() != QFile::NoError) {
            if (errorMessage)
                *errorMessage = QStringLiteral("Failed while reading file: %1").arg(sourcePath);
            return false;
        }

        const qint64 written = dest.write(chunk);
        if (written != chunk.size()) {
            if (errorMessage)
                *errorMessage = QStringLiteral("Failed while writing file: %1").arg(destPath);
            return false;
        }

        reporter.advance(written);
    }

    dest.close();
    source.close();
    return true;
}

bool copyRecursivelyChunked(const QString& sourcePath,
                            const QString& destPath,
                            ProgressReporter& reporter,
                            QString* errorMessage)
{
    QFileInfo sourceInfo(sourcePath);
    if (!sourceInfo.exists()) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Source item does not exist: %1").arg(sourcePath);
        return false;
    }

    if (sourceInfo.isDir()) {
        if (!QDir().mkpath(destPath)) {
            if (errorMessage)
                *errorMessage = QStringLiteral("Failed to create destination folder: %1").arg(destPath);
            return false;
        }

        QDir srcDir(sourcePath);
        const QFileInfoList entries = srcDir.entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);

        for (const QFileInfo& entry : entries) {
            const QString nextSource = entry.absoluteFilePath();
            const QString nextDest = QDir(destPath).filePath(entry.fileName());
            if (!copyRecursivelyChunked(nextSource, nextDest, reporter, errorMessage))
                return false;
        }

        return true;
    }

    return copyFileChunked(sourcePath, destPath, reporter, errorMessage);
}

bool movePathSmartChunked(const QString& sourcePath,
                          const QString& destPath,
                          ProgressReporter& reporter,
                          QString* errorMessage)
{
    if (QFile::rename(sourcePath, destPath)) {
        reporter.advance(totalBytesForPath(destPath));
        return true;
    }

    if (!copyRecursivelyChunked(sourcePath, destPath, reporter, errorMessage))
        return false;

    if (!removeRecursively(sourcePath)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Copied item but failed to remove source: %1").arg(sourcePath);
        return false;
    }

    return true;
}

bool deletePathWithProgress(const QString& path,
                            ProgressReporter& reporter,
                            QString* errorMessage)
{
    QFileInfo info(path);
    if (!info.exists())
        return true;

    if (info.isDir()) {
        QDir dir(path);
        const QFileInfoList entries = dir.entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);

        for (const QFileInfo& entry : entries) {
            if (!deletePathWithProgress(entry.absoluteFilePath(), reporter, errorMessage))
                return false;
        }

        if (!QDir().rmdir(path)) {
            if (errorMessage)
                *errorMessage = QStringLiteral("Failed to remove folder: %1").arg(path);
            return false;
        }

        return true;
    }

    const qint64 fileBytes = qMax<qint64>(0, info.size());
    if (!QFile::remove(path)) {
        if (errorMessage)
            *errorMessage = QStringLiteral("Failed to delete file: %1").arg(path);
        return false;
    }

    reporter.advance(fileBytes);
    return true;
}
}

WorkspaceViewModel::WorkspaceViewModel(QObject* parent)
    : QObject(parent)
    , m_viewMode(normalizeViewMode(m_settings.viewMode()))
    , m_sortField(normalizeSortField(m_settings.sortField()))
    , m_sortDescending(m_settings.sortDescending())
{
    const QVariantList savedTabs = m_settings.tabs();
    QString initialPath = QStringLiteral("C:/");

    const int savedIndex = qMax(0, m_settings.currentTabIndex());
    if (savedIndex >= 0 && savedIndex < savedTabs.size()) {
        const QVariantMap tab = savedTabs.at(savedIndex).toMap();
        const QString path = tab.value(QStringLiteral("path")).toString().trimmed();
        if (!path.isEmpty())
            initialPath = path;
    }

    loadLocation(initialPath, true);
}

FileListModel* WorkspaceViewModel::fileModel()
{
    return &m_fileModel;
}

QString WorkspaceViewModel::viewMode() const
{
    return m_viewMode;
}

QString WorkspaceViewModel::viewModeIcon() const
{
    return iconForViewMode(m_viewMode);
}

int WorkspaceViewModel::currentIndex() const
{
    return m_currentIndex;
}

int WorkspaceViewModel::totalItems() const
{
    return m_fileModel.rowCount();
}

int WorkspaceViewModel::selectedItems() const
{
    return m_selectedRows.size();
}

QString WorkspaceViewModel::itemsText() const
{
    if (selectedItems() > 0) {
        return QString::number(totalItems())
        + QStringLiteral(" items  ")
            + QString::number(selectedItems())
            + QStringLiteral(" selected");
    }

    return QString::number(totalItems()) + QStringLiteral(" items");
}

bool WorkspaceViewModel::dragSelecting() const
{
    return m_dragSelecting;
}

int WorkspaceViewModel::selectionRevision() const
{
    return m_selectionRevision;
}

QString WorkspaceViewModel::sortField() const
{
    return m_sortField;
}

bool WorkspaceViewModel::sortDescending() const
{
    return m_sortDescending;
}

QString WorkspaceViewModel::currentDirectoryPath() const
{
    return m_currentDirectoryPath;
}

void WorkspaceViewModel::setCurrentDirectoryPath(const QString& value)
{
    loadLocation(value, true);
}

bool WorkspaceViewModel::draggingItems() const
{
    return m_draggingItems;
}

QVariantList WorkspaceViewModel::draggedItems() const
{
    return m_draggedItems;
}

QString WorkspaceViewModel::draggedPathsText() const
{
    QStringList paths;
    paths.reserve(m_draggedItems.size());

    for (const QVariant& entry : m_draggedItems) {
        const QVariantMap item = entry.toMap();
        const QString path = item.value(QStringLiteral("path")).toString();
        if (!path.isEmpty())
            paths.push_back(path);
    }

    return paths.join(QLatin1Char('\n'));
}

bool WorkspaceViewModel::dragPreviewVisible() const
{
    return m_dragPreviewVisible;
}

qreal WorkspaceViewModel::dragPreviewX() const
{
    return m_dragPreviewX;
}

qreal WorkspaceViewModel::dragPreviewY() const
{
    return m_dragPreviewY;
}

QString WorkspaceViewModel::dragPreviewText() const
{
    return m_dragPreviewText;
}

QString WorkspaceViewModel::dragPreviewIcon() const
{
    return m_dragPreviewIcon;
}

int WorkspaceViewModel::inlineEditRow() const
{
    return m_inlineEditRow;
}

QString WorkspaceViewModel::inlineEditText() const
{
    return m_inlineEditText;
}

QString WorkspaceViewModel::inlineEditError() const
{
    return m_inlineEditError;
}

bool WorkspaceViewModel::inlineEditIsNew() const
{
    return m_inlineEditIsNew;
}

int WorkspaceViewModel::inlineEditFocusToken() const
{
    return m_inlineEditFocusToken;
}

QVariantList WorkspaceViewModel::openWithApps() const
{
    return m_openWithApps;
}

void WorkspaceViewModel::setViewMode(const QString& value)
{
    const QString resolved = normalizeViewMode(value);
    if (m_viewMode == resolved)
        return;

    m_viewMode = resolved;
    m_settings.setViewMode(m_viewMode);
    emit viewModeChanged();
}

void WorkspaceViewModel::goBack()
{
    if (m_historyIndex <= 0)
        return;

    --m_historyIndex;
    loadLocation(m_history.at(m_historyIndex), false);
}

void WorkspaceViewModel::goForward()
{
    if (m_historyIndex < 0 || m_historyIndex >= m_history.size() - 1)
        return;

    ++m_historyIndex;
    loadLocation(m_history.at(m_historyIndex), false);
}

void WorkspaceViewModel::goUp()
{
    const QString parentPath = parentLocationForPath(m_currentDirectoryPath);
    if (parentPath == normalizePath(m_currentDirectoryPath))
        return;

    loadLocation(parentPath, true);
}

void WorkspaceViewModel::refresh()
{
    reloadListing();
}

void WorkspaceViewModel::navigateToPathString(const QString& path)
{
    loadLocation(path, true);
}

void WorkspaceViewModel::search(const QString& query, const QString& scope)
{
    m_activeSearch = query.trimmed();
    m_activeSearchScope = scope.trimmed() == QStringLiteral("global")
                              ? QStringLiteral("global")
                              : QStringLiteral("folder");
    reloadListing();
}

void WorkspaceViewModel::setShowHiddenFiles(bool value)
{
    if (m_settings.showHiddenFiles() == value)
        return;

    m_settings.setShowHiddenFiles(value);
    reloadListing();
}

QString WorkspaceViewModel::savedViewMode() const
{
    return m_settings.viewMode();
}

bool WorkspaceViewModel::savedShowHiddenFiles() const
{
    return m_settings.showHiddenFiles();
}

void WorkspaceViewModel::setSort(const QString& field, bool descending)
{
    const QString normalizedField = normalizeSortField(field);
    if (m_sortField == normalizedField && m_sortDescending == descending)
        return;

    m_sortField = normalizedField;
    m_sortDescending = descending;
    m_settings.setSortField(m_sortField);
    m_settings.setSortDescending(m_sortDescending);
    emit sortChanged();
    reloadListing();
}

void WorkspaceViewModel::toggleSort(const QString& field)
{
    const QString normalizedField = normalizeSortField(field);
    if (m_sortField == normalizedField) {
        setSort(normalizedField, !m_sortDescending);
        return;
    }

    setSort(normalizedField, false);
}

void WorkspaceViewModel::activateRow(int row)
{
    if (!isValidRow(row))
        return;

    if (m_currentIndex == row)
        return;

    m_currentIndex = row;
    emit currentIndexChanged();
}

void WorkspaceViewModel::selectOnlyRow(int row)
{
    if (!isValidRow(row))
        return;

    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;

    m_selectedRows.clear();
    m_selectedRows.insert(row);
    m_selectionAnchorRow = row;

    if (m_currentIndex != row) {
        m_currentIndex = row;
        emit currentIndexChanged();
    }

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
}

void WorkspaceViewModel::toggleRowSelection(int row)
{
    if (!isValidRow(row))
        return;

    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;

    if (m_selectedRows.contains(row)) {
        if (m_selectedRows.size() > 1)
            m_selectedRows.remove(row);
    } else {
        m_selectedRows.insert(row);
    }

    m_selectionAnchorRow = row;

    if (m_currentIndex != row) {
        m_currentIndex = row;
        emit currentIndexChanged();
    }

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
}

void WorkspaceViewModel::selectRange(int startRow, int endRow)
{
    if (!isValidRow(startRow) || !isValidRow(endRow))
        return;

    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;

    m_selectedRows.clear();

    const int from = std::min(startRow, endRow);
    const int to = std::max(startRow, endRow);

    for (int i = from; i <= to; ++i)
        m_selectedRows.insert(i);

    m_selectionAnchorRow = startRow;

    if (m_currentIndex != endRow) {
        m_currentIndex = endRow;
        emit currentIndexChanged();
    }

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
}

void WorkspaceViewModel::clickRow(int row, int modifiers)
{
    if (!isValidRow(row))
        return;

    const Qt::KeyboardModifiers keyboardModifiers =
        static_cast<Qt::KeyboardModifiers>(modifiers);

    if (keyboardModifiers.testFlag(Qt::ShiftModifier)) {
        const int anchor =
            (m_selectionAnchorRow >= 0 && m_selectionAnchorRow < m_fileModel.rowCount())
                ? m_selectionAnchorRow
                : row;
        selectRange(anchor, row);
        return;
    }

    if (keyboardModifiers.testFlag(Qt::ControlModifier)) {
        toggleRowSelection(row);
        return;
    }

    selectOnlyRow(row);
}

void WorkspaceViewModel::openRow(int row)
{
    if (!isValidRow(row))
        return;

    if (row == m_inlineEditRow)
        return;

    selectOnlyRow(row);

    const QVariantMap item = fileAt(row);
    const QString path = item.value(QStringLiteral("path")).toString();

    if (item.value(QStringLiteral("isDir")).toBool()) {
        loadLocation(path, true);
        emit openDirectoryRequested(item);
        return;
    }

    const bool ok = FileAssociationService::openWithDefaultApp(path);

    emit openFileRequested(item);

    if (ok)
        emit operationCompleted(QStringLiteral("Opened %1").arg(item.value(QStringLiteral("name")).toString()));
    else
        emit operationFailed(
            QStringLiteral("Failed to open %1").arg(item.value(QStringLiteral("name")).toString()));
}

bool WorkspaceViewModel::isRowSelected(int row) const
{
    return m_selectedRows.contains(row);
}

QVariantMap WorkspaceViewModel::fileAt(int row) const
{
    return m_fileModel.get(row);
}

QVariantMap WorkspaceViewModel::previewData() const
{
    if (m_selectedRows.isEmpty())
        return {};

    if (m_selectedRows.size() == 1)
        return previewDataForRow(firstSelectedRow());

    QList<int> rows = m_selectedRows.values();
    std::sort(rows.begin(), rows.end());

    int folderCount = 0;
    int fileCount = 0;
    QVariantList lines;

    for (int row : rows) {
        const QVariantMap item = fileAt(row);
        const QString name = item.value(QStringLiteral("name")).toString();
        const QString type = item.value(QStringLiteral("type")).toString();

        if (item.value(QStringLiteral("isDir")).toBool())
            ++folderCount;
        else
            ++fileCount;

        lines.push_back(QStringLiteral("%1 - %2").arg(name, type));
    }

    QVariantMap data;
    data.insert(QStringLiteral("visible"), true);
    data.insert(QStringLiteral("name"), QStringLiteral("%1 items selected").arg(rows.size()));
    data.insert(QStringLiteral("type"), QStringLiteral("Multiple items"));
    data.insert(QStringLiteral("icon"), QStringLiteral("preview"));
    data.insert(QStringLiteral("previewType"), QStringLiteral("multi"));
    data.insert(QStringLiteral("size"), QString());
    data.insert(QStringLiteral("dateModified"), QString());
    data.insert(
        QStringLiteral("summary"),
        QStringLiteral("%1 folder(s), %2 file(s)").arg(folderCount).arg(fileCount));
    data.insert(QStringLiteral("lines"), lines);
    return data;
}

void WorkspaceViewModel::beginDragSelection(int anchorRow)
{
    if (!isValidRow(anchorRow))
        return;

    if (!m_dragSelecting) {
        m_dragSelecting = true;
        emit dragSelectingChanged();
    }

    cancelFileDrag();

    m_selectionAnchorRow = anchorRow;
    selectRange(anchorRow, anchorRow);
}

void WorkspaceViewModel::updateDragSelection(int targetRow)
{
    if (!m_dragSelecting)
        return;

    if (!isValidRow(targetRow))
        return;

    const int anchor =
        (m_selectionAnchorRow >= 0 && m_selectionAnchorRow < m_fileModel.rowCount())
            ? m_selectionAnchorRow
            : targetRow;

    selectRange(anchor, targetRow);
}

void WorkspaceViewModel::replaceSelectionRows(const QVariantList& rows, int currentRow, int anchorRow)
{
    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;

    QSet<int> nextRows;
    const int count = m_fileModel.rowCount();

    for (const QVariant& value : rows) {
        const int row = value.toInt();
        if (row >= 0 && row < count)
            nextRows.insert(row);
    }

    if (nextRows.isEmpty())
        return;

    m_selectedRows = nextRows;

    if (anchorRow >= 0 && anchorRow < count)
        m_selectionAnchorRow = anchorRow;

    if (currentRow >= 0 && currentRow < count && m_currentIndex != currentRow) {
        m_currentIndex = currentRow;
        emit currentIndexChanged();
    }

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
}

void WorkspaceViewModel::endDragSelection()
{
    if (!m_dragSelecting)
        return;

    m_dragSelecting = false;
    emit dragSelectingChanged();
}

void WorkspaceViewModel::startFileDrag(int row, int modifiers)
{
    if (!isValidRow(row))
        return;

    if (m_dragSelecting)
        return;

    if (row == m_inlineEditRow)
        return;

    Q_UNUSED(modifiers);

    if (!m_selectedRows.contains(row))
        selectOnlyRow(row);
    else
        activateRow(row);

    const QVariantList nextDraggedItems = buildDraggedItems();
    if (nextDraggedItems.isEmpty())
        return;

    m_draggedItems = nextDraggedItems;
    m_lastDropTargetPath.clear();
    m_lastDropTargetKind.clear();

    if (m_draggingItems)
        return;

    m_draggingItems = true;
    emit draggingItemsChanged();
}

void WorkspaceViewModel::finishFileDrag(bool accepted)
{
    if (!m_draggingItems)
        return;

    const bool resolvedAccepted =
        accepted
        && !m_lastDropTargetPath.trimmed().isEmpty()
        && !m_lastDropTargetKind.trimmed().isEmpty();

    emit fileDragFinished(
        resolvedAccepted,
        resolvedAccepted ? m_lastDropTargetPath : QString(),
        resolvedAccepted ? m_lastDropTargetKind : QString());

    clearDragState();
}

void WorkspaceViewModel::cancelFileDrag()
{
    if (!m_draggingItems)
        return;

    emit fileDragFinished(false, QString(), QString());
    clearDragState();
}

bool WorkspaceViewModel::canDropOnRow(int row) const
{
    if (!isValidRow(row))
        return false;

    const QVariantMap item = fileAt(row);
    if (!item.value(QStringLiteral("isDir")).toBool())
        return false;

    return canDropToPath(item.value(QStringLiteral("path")).toString());
}

bool WorkspaceViewModel::canDropToPath(const QString& targetPath) const
{
    if (!m_draggingItems)
        return false;

    const QString normalized = normalizePath(targetPath);
    if (normalized.isEmpty())
        return false;

    for (const QVariant& entry : m_draggedItems) {
        const QVariantMap item = entry.toMap();
        const QString draggedPath = normalizePath(item.value(QStringLiteral("path")).toString());
        if (draggedPath.isEmpty())
            continue;

        if (draggedPath.compare(normalized, Qt::CaseInsensitive) == 0)
            return false;

        const QString parentPath = normalizePath(QFileInfo(draggedPath).dir().absolutePath());
        if (parentPath.compare(normalized, Qt::CaseInsensitive) == 0)
            return false;

        QFileInfo draggedInfo(draggedPath);
        if (draggedInfo.isDir()) {
            const QString descendantPrefix = draggedPath.endsWith(QLatin1Char('/'))
                                                 ? draggedPath
                                                 : draggedPath + QLatin1Char('/');
            if (normalized.startsWith(descendantPrefix, Qt::CaseInsensitive))
                return false;
        }

        if (!draggedInfo.exists())
            return false;
    }

    return true;
}

void WorkspaceViewModel::dropOnRow(int row, bool copy)
{
    if (!canDropOnRow(row))
        return;

    const QVariantMap item = fileAt(row);
    requestDropToPath(item.value(QStringLiteral("path")).toString(), QStringLiteral("folder"), copy);
}

void WorkspaceViewModel::requestDropToPath(const QString& targetPath, const QString& targetKind, bool copy)
{
    if (!canDropToPath(targetPath))
        return;

    m_lastDropTargetPath = targetPath;
    m_lastDropTargetKind = targetKind.trimmed().isEmpty() ? QStringLiteral("path") : targetKind;

    emit fileDropRequested(
        m_draggedItems,
        m_lastDropTargetPath,
        m_lastDropTargetKind,
        copy);
}

void WorkspaceViewModel::performDropOperation(const QVariantList& draggedItems, const QString& targetPath, bool copy)
{
    const QString destinationDirectory = normalizePath(targetPath);
    if (destinationDirectory.isEmpty()) {
        emit operationFailed(QStringLiteral("Drop target is invalid."));
        return;
    }

    QFileInfo destinationInfo(destinationDirectory);
    if (!destinationInfo.exists() || !destinationInfo.isDir()) {
        emit operationFailed(QStringLiteral("Drop target is unavailable."));
        return;
    }

    QStringList sourcePaths;
    QSet<QString> seenPaths;

    for (const QVariant& entry : draggedItems) {
        const QVariantMap item = entry.toMap();
        const QString sourcePath = normalizePath(item.value(QStringLiteral("path")).toString());
        if (sourcePath.isEmpty() || seenPaths.contains(sourcePath))
            continue;

        QFileInfo sourceInfo(sourcePath);
        if (!sourceInfo.exists())
            continue;

        seenPaths.insert(sourcePath);
        sourcePaths.push_back(sourcePath);
    }

    if (sourcePaths.isEmpty()) {
        emit operationFailed(copy ? QStringLiteral("Nothing to copy.")
                                  : QStringLiteral("Nothing to move."));
        return;
    }

    startAsyncTransferOperation(
        sourcePaths,
        destinationDirectory,
        copy,
        copy ? QStringLiteral("Copied %1 item(s)") : QStringLiteral("Moved %1 item(s)"),
        copy ? QStringLiteral("Copy failed.") : QStringLiteral("Move failed."));
}

bool WorkspaceViewModel::isOnlyDraggingRow(int row) const
{
    if (!m_draggingItems || m_draggedItems.size() != 1 || !isValidRow(row))
        return false;

    const QString rowPath = fileAt(row).value(QStringLiteral("path")).toString();
    const QString draggedPath = m_draggedItems.first().toMap().value(QStringLiteral("path")).toString();

    return rowPath.compare(draggedPath, Qt::CaseInsensitive) == 0;
}

void WorkspaceViewModel::beginFileDragPreview(qreal overlayX, qreal overlayY, const QString& text, const QString& icon)
{
    const QString resolvedText = text.trimmed();
    const QString resolvedIcon = icon.trimmed().isEmpty()
                                     ? QStringLiteral("insert-drive-file")
                                     : icon.trimmed();

    const bool changed =
        !m_dragPreviewVisible
        || !qFuzzyCompare(m_dragPreviewX + 1.0, overlayX + 1.0)
        || !qFuzzyCompare(m_dragPreviewY + 1.0, overlayY + 1.0)
        || m_dragPreviewText != resolvedText
        || m_dragPreviewIcon != resolvedIcon;

    m_dragPreviewVisible = true;
    m_dragPreviewX = overlayX;
    m_dragPreviewY = overlayY;
    m_dragPreviewText = resolvedText;
    m_dragPreviewIcon = resolvedIcon;

    if (changed)
        emit dragPreviewChanged();
}

void WorkspaceViewModel::updateFileDragPreview(qreal overlayX, qreal overlayY)
{
    if (!m_dragPreviewVisible)
        return;

    if (qFuzzyCompare(m_dragPreviewX + 1.0, overlayX + 1.0)
        && qFuzzyCompare(m_dragPreviewY + 1.0, overlayY + 1.0)) {
        return;
    }

    m_dragPreviewX = overlayX;
    m_dragPreviewY = overlayY;
    emit dragPreviewChanged();
}

void WorkspaceViewModel::endFileDragPreview()
{
    if (!m_dragPreviewVisible)
        return;

    clearDragPreview();
}

void WorkspaceViewModel::requestFileContextAction(const QString& action, int row)
{
    if (!isValidRow(row))
        return;

    const QString trimmedAction = action.trimmed();

    const bool rowAlreadySelected = m_selectedRows.contains(row);
    if (!rowAlreadySelected)
        selectOnlyRow(row);

    if (trimmedAction.compare(QStringLiteral("Rename"), Qt::CaseInsensitive) == 0) {
        beginRenameRow(row);
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Copy"), Qt::CaseInsensitive) == 0) {
        copySelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Cut"), Qt::CaseInsensitive) == 0) {
        cutSelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Delete"), Qt::CaseInsensitive) == 0) {
        deleteSelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Copy path"), Qt::CaseInsensitive) == 0) {
        copySelectedPathTextToClipboard();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Duplicate"), Qt::CaseInsensitive) == 0) {
        duplicateSelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Open containing folder"), Qt::CaseInsensitive) == 0) {
        openContainingFolderForSelection();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Compress"), Qt::CaseInsensitive) == 0) {
        compressSelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Extract here"), Qt::CaseInsensitive) == 0
        || trimmedAction.compare(QStringLiteral("Extract"), Qt::CaseInsensitive) == 0) {
        extractSelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Properties"), Qt::CaseInsensitive) == 0) {
        showItemProperties();
        return;
    }

    emit fileContextActionRequested(trimmedAction, fileAt(row));
}

void WorkspaceViewModel::createFolder()
{
    createPendingItem(true);
}

void WorkspaceViewModel::createFile()
{
    createPendingItem(false);
}

void WorkspaceViewModel::beginRenameRow(int row)
{
    if (!isValidRow(row))
        return;

    if (m_inlineEditRow >= 0 && m_inlineEditRow != row) {
        if (!commitInlineEdit())
            return;
    }

    selectOnlyRow(row);

    const QVariantMap item = fileAt(row);
    setInlineEditState(row, item.value(QStringLiteral("name")).toString(), false);
}

void WorkspaceViewModel::renameSelectedItems()
{
    const int row = firstSelectedRow();
    if (row >= 0)
        beginRenameRow(row);
}

void WorkspaceViewModel::updateInlineEditText(const QString& text)
{
    if (m_inlineEditRow < 0)
        return;

    if (m_inlineEditText == text)
        return;

    m_inlineEditText = text;
    emit inlineEditTextChanged();

    setInlineEditError(validateInlineEditText(m_inlineEditText));
}

bool WorkspaceViewModel::commitInlineEdit()
{
    if (m_inlineEditRow < 0 || !isValidRow(m_inlineEditRow))
        return true;

    const QString trimmed = m_inlineEditText.trimmed();
    const QString error = validateInlineEditText(trimmed);
    setInlineEditError(error);
    if (!error.isEmpty())
        return false;

    const QVariantMap existingMap = fileAt(m_inlineEditRow);
    const bool isDir = existingMap.value(QStringLiteral("isDir")).toBool();
    const QString oldName = existingMap.value(QStringLiteral("name")).toString();
    const QString oldPath = existingMap.value(QStringLiteral("path")).toString();

    if (m_inlineEditIsNew) {
        const QString newPath = childLocationForName(m_currentDirectoryPath, trimmed);

        bool ok = false;
        QString operationError;

        if (isDir) {
            ok = QDir().mkpath(newPath);
        } else {
            QFile f(newPath);
            ok = f.open(QIODevice::WriteOnly);
            if (ok)
                f.close();
        }

        if (!ok) {
            setInlineEditError(operationError.isEmpty()
                                   ? QStringLiteral("Failed to create item.")
                                   : operationError);
            return false;
        }

        emit operationCompleted(QStringLiteral("Created %1").arg(trimmed));
    } else if (oldName.compare(trimmed, Qt::CaseInsensitive) != 0) {
        const QString newPath = childLocationForName(parentLocationForPath(oldPath), trimmed);

        bool ok = false;
        QString operationError;

        ok = QFile::rename(oldPath, newPath);

        if (!ok) {
            setInlineEditError(operationError.isEmpty()
                                   ? QStringLiteral("Failed to rename item.")
                                   : operationError);
            return false;
        }

        emit operationCompleted(QStringLiteral("Renamed %1 to %2").arg(oldName, trimmed));
    }

    clearInlineEditState();
    reloadListing();
    return true;
}

void WorkspaceViewModel::cancelInlineEdit()
{
    if (m_inlineEditRow < 0)
        return;

    if (m_inlineEditIsNew && isValidRow(m_inlineEditRow)) {
        const int previousSelected = selectedItems();
        const QString previousItemsText = itemsText();
        const QSet<int> previousRows = m_selectedRows;
        const int previousCurrentIndex = m_currentIndex;

        m_fileModel.removeItem(m_inlineEditRow);
        emit totalItemsChanged();

        m_selectedRows.clear();

        if (m_fileModel.rowCount() > 0) {
            m_selectedRows.insert(0);
            m_selectionAnchorRow = 0;
            m_currentIndex = 0;
        } else {
            m_selectionAnchorRow = -1;
            m_currentIndex = -1;
        }

        if (previousCurrentIndex != m_currentIndex)
            emit currentIndexChanged();

        emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
    }

    clearInlineEditState();
}

void WorkspaceViewModel::cutSelectedItems()
{
    const QStringList paths = selectedPaths();
    if (paths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing selected to cut."));
        return;
    }

    m_clipboardMode = ClipboardMode::Cut;
    m_clipboardPaths = paths;

    if (QGuiApplication::clipboard()) {
        auto* mimeData = new QMimeData;
        QList<QUrl> urls;
        urls.reserve(paths.size());
        for (const QString& path : paths)
            urls.push_back(QUrl::fromLocalFile(path));
        mimeData->setUrls(urls);
        mimeData->setText(paths.join(QLatin1Char('\n')));
        QGuiApplication::clipboard()->setMimeData(mimeData);
    }

    emit operationCompleted(QStringLiteral("Cut %1 item(s)").arg(paths.size()));
}

void WorkspaceViewModel::copySelectedItems()
{
    const QStringList paths = selectedPaths();
    if (paths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing selected to copy."));
        return;
    }

    m_clipboardMode = ClipboardMode::Copy;
    m_clipboardPaths = paths;

    if (QGuiApplication::clipboard()) {
        auto* mimeData = new QMimeData;
        QList<QUrl> urls;
        urls.reserve(paths.size());
        for (const QString& path : paths)
            urls.push_back(QUrl::fromLocalFile(path));
        mimeData->setUrls(urls);
        mimeData->setText(paths.join(QLatin1Char('\n')));
        QGuiApplication::clipboard()->setMimeData(mimeData);
    }

    emit operationCompleted(QStringLiteral("Copied %1 item(s)").arg(paths.size()));
}

void WorkspaceViewModel::pasteItems()
{
    QStringList sourcePaths;
    bool copy = true;

    if (!m_clipboardPaths.isEmpty() && m_clipboardMode != ClipboardMode::None) {
        sourcePaths = m_clipboardPaths;
        copy = m_clipboardMode == ClipboardMode::Copy;

        if (m_clipboardMode == ClipboardMode::Cut) {
            m_clipboardMode = ClipboardMode::None;
            m_clipboardPaths.clear();
        }
    } else if (QGuiApplication::clipboard() && QGuiApplication::clipboard()->mimeData()) {
        const QMimeData* mimeData = QGuiApplication::clipboard()->mimeData();
        const QList<QUrl> urls = mimeData->urls();
        for (const QUrl& url : urls) {
            if (!url.isLocalFile())
                continue;

            const QString localPath = normalizePath(url.toLocalFile());
            if (!localPath.isEmpty())
                sourcePaths.push_back(localPath);
        }
        sourcePaths.removeDuplicates();
        copy = true;
    }

    if (sourcePaths.isEmpty()) {
        emit operationFailed(QStringLiteral("Clipboard is empty."));
        return;
    }

    startAsyncTransferOperation(
        sourcePaths,
        m_currentDirectoryPath,
        copy,
        copy ? QStringLiteral("Pasted %1 item(s)") : QStringLiteral("Moved %1 item(s)"),
        QStringLiteral("Paste failed."));
}

void WorkspaceViewModel::duplicateSelectedItems()
{
    const QStringList sourcePaths = selectedPaths();
    if (sourcePaths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing to duplicate."));
        return;
    }

    startAsyncDuplicateOperation(sourcePaths);
}

void WorkspaceViewModel::startAsyncTransferOperation(const QStringList& sourcePaths,
                                                     const QString& destinationDirectory,
                                                     bool copy,
                                                     const QString& successMessageTemplate,
                                                     const QString& failureMessage)
{
    const QString normalizedDestination = normalizePath(destinationDirectory);
    if (normalizedDestination.isEmpty()) {
        emit operationFailed(QStringLiteral("Destination is invalid."));
        return;
    }

    QFileInfo destinationInfo(normalizedDestination);
    if (!destinationInfo.exists() || !destinationInfo.isDir()) {
        emit operationFailed(QStringLiteral("Destination is unavailable."));
        return;
    }

    if (sourcePaths.isEmpty()) {
        emit operationFailed(failureMessage);
        return;
    }

    qint64 totalBytes = 0;
    for (const QString& path : sourcePaths)
        totalBytes += totalBytesForPath(path);

    const QString progressTitle = copy ? QStringLiteral("Copying items")
                                       : QStringLiteral("Moving items");

    emit operationProgress(
        progressTitle,
        QStringLiteral("0 B of %1").arg(formatBytes(totalBytes)),
        0,
        false);

    auto* watcher = new QFutureWatcher<AsyncOperationResult>(this);

    connect(watcher, &QFutureWatcher<AsyncOperationResult>::finished, this, [this, watcher]() {
        const AsyncOperationResult result = watcher->result();
        watcher->deleteLater();

        reloadListing();

        if (result.ok)
            emit operationCompleted(result.successMessage);
        else
            emit operationFailed(result.errorMessage);
    });

    watcher->setFuture(QtConcurrent::run([target = QPointer<WorkspaceViewModel>(this),
                                          sourcePaths,
                                          normalizedDestination,
                                          copy,
                                          totalBytes,
                                          progressTitle,
                                          successMessageTemplate,
                                          failureMessage]() -> AsyncOperationResult {
        AsyncOperationResult result;
        ProgressReporter reporter(target, progressTitle, totalBytes);

        int successCount = 0;

        for (const QString& sourcePath : sourcePaths) {
            QFileInfo srcInfo(sourcePath);
            if (!srcInfo.exists())
                continue;

            const QString destPath = uniquePathInDirectory(normalizedDestination, srcInfo.fileName());

            QString error;
            bool ok = false;

            if (copy)
                ok = copyRecursivelyChunked(sourcePath, destPath, reporter, &error);
            else
                ok = movePathSmartChunked(sourcePath, destPath, reporter, &error);

            if (!ok) {
                result.ok = false;
                result.errorMessage = error.isEmpty() ? failureMessage : error;
                return result;
            }

            ++successCount;
        }

        reporter.finish();

        result.ok = successCount > 0;
        result.affectedCount = successCount;

        if (result.ok)
            result.successMessage = successMessageTemplate.arg(successCount);
        else
            result.errorMessage = failureMessage;

        return result;
    }));
}

void WorkspaceViewModel::showProperties()
{
    showItemProperties();
}

void WorkspaceViewModel::showItemProperties()
{
    const int row = firstSelectedRow();
    if (row < 0 || !isValidRow(row)) {
        emit operationFailed(QStringLiteral("No item selected."));
        return;
    }

    emitPropertiesForItem(fileAt(row));
}

void WorkspaceViewModel::showCurrentLocationProperties()
{
    QVariantMap item;
    {
        QFileInfo info(m_currentDirectoryPath);
        item.insert(QStringLiteral("name"), info.fileName().isEmpty() ? m_currentDirectoryPath : info.fileName());
        item.insert(QStringLiteral("type"), QStringLiteral("Folder"));
        item.insert(QStringLiteral("icon"), QStringLiteral("folder"));
        item.insert(QStringLiteral("isDir"), true);
    }
    item.insert(QStringLiteral("path"), m_currentDirectoryPath);
    item.insert(QStringLiteral("size"), QString());
    emitPropertiesForItem(item);
}

void WorkspaceViewModel::startAsyncDuplicateOperation(const QStringList& sourcePaths)
{
    if (sourcePaths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing to duplicate."));
        return;
    }

    qint64 totalBytes = 0;
    for (const QString& path : sourcePaths)
        totalBytes += totalBytesForPath(path);

    emit operationProgress(
        QStringLiteral("Duplicating items"),
        QStringLiteral("0 B of %1").arg(formatBytes(totalBytes)),
        0,
        false);

    auto* watcher = new QFutureWatcher<AsyncOperationResult>(this);

    connect(watcher, &QFutureWatcher<AsyncOperationResult>::finished, this, [this, watcher]() {
        const AsyncOperationResult result = watcher->result();
        watcher->deleteLater();

        reloadListing();

        if (result.ok)
            emit operationCompleted(result.successMessage);
        else
            emit operationFailed(result.errorMessage);
    });

    watcher->setFuture(QtConcurrent::run([target = QPointer<WorkspaceViewModel>(this),
                                          sourcePaths,
                                          totalBytes]() -> AsyncOperationResult {
        AsyncOperationResult result;
        ProgressReporter reporter(target, QStringLiteral("Duplicating items"), totalBytes);

        int successCount = 0;

        for (const QString& sourcePath : sourcePaths) {
            QFileInfo srcInfo(sourcePath);
            if (!srcInfo.exists())
                continue;

            const QString destinationDirectory = srcInfo.dir().absolutePath();
            const QString destPath = uniquePathInDirectory(destinationDirectory, srcInfo.fileName());

            QString error;
            if (!copyRecursivelyChunked(sourcePath, destPath, reporter, &error)) {
                result.ok = false;
                result.errorMessage = error.isEmpty()
                                          ? QStringLiteral("Duplicate failed.")
                                          : error;
                return result;
            }

            ++successCount;
        }

        reporter.finish();

        result.ok = successCount > 0;
        result.affectedCount = successCount;

        if (result.ok)
            result.successMessage = QStringLiteral("Duplicated %1 item(s)").arg(successCount);
        else
            result.errorMessage = QStringLiteral("Duplicate failed.");

        return result;
    }));
}

void WorkspaceViewModel::deleteSelectedItems()
{
    const QStringList paths = selectedPaths();
    if (paths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing selected to delete."));
        return;
    }

    qint64 totalBytes = 0;
    for (const QString& path : paths)
        totalBytes += totalBytesForPath(path);

    emit operationProgress(
        QStringLiteral("Deleting items"),
        QStringLiteral("0 B of %1").arg(formatBytes(totalBytes)),
        0,
        false);

    auto* watcher = new QFutureWatcher<AsyncOperationResult>(this);

    connect(watcher, &QFutureWatcher<AsyncOperationResult>::finished, this, [this, watcher]() {
        const AsyncOperationResult result = watcher->result();
        watcher->deleteLater();

        reloadListing();

        if (result.ok)
            emit operationCompleted(result.successMessage);
        else
            emit operationFailed(result.errorMessage);
    });

    watcher->setFuture(QtConcurrent::run([target = QPointer<WorkspaceViewModel>(this),
                                          paths,
                                          totalBytes]() -> AsyncOperationResult {
        AsyncOperationResult result;
        ProgressReporter reporter(target, QStringLiteral("Deleting items"), totalBytes);

        int deleted = 0;
        for (const QString& path : paths) {
            QString error;
            if (!deletePathWithProgress(path, reporter, &error)) {
                result.ok = false;
                result.errorMessage = error.isEmpty()
                                          ? QStringLiteral("Delete failed.")
                                          : error;
                return result;
            }

            ++deleted;
        }

        reporter.finish();

        result.ok = deleted > 0;
        result.affectedCount = deleted;

        if (result.ok)
            result.successMessage = QStringLiteral("Deleted %1 item(s)").arg(deleted);
        else
            result.errorMessage = QStringLiteral("Delete failed.");

        return result;
    }));
}

void WorkspaceViewModel::compressSelectedItems()
{
    const QStringList paths = selectedPaths();
    if (paths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing selected to compress."));
        return;
    }

    QString archiveName = paths.size() == 1
                              ? QFileInfo(paths.first()).completeBaseName() + QStringLiteral(".zip")
                              : QStringLiteral("Archive.zip");
    const QString archivePath = uniquePathInDirectory(m_currentDirectoryPath, archiveName);

    bool ok = false;

#ifdef Q_OS_WINDOWS
    QStringList quoted;
    for (const QString& p : paths)
        quoted.push_back(quotePs(QDir::toNativeSeparators(p)));

    const QString script = QStringLiteral(
                               "Compress-Archive -LiteralPath %1 -DestinationPath %2 -Force")
                               .arg(QStringLiteral("@(") + quoted.join(QStringLiteral(",")) + QStringLiteral(")"))
                               .arg(quotePs(QDir::toNativeSeparators(archivePath)));

    ok = QProcess::execute(
             QStringLiteral("powershell"),
             { QStringLiteral("-NoProfile"), QStringLiteral("-Command"), script }) == 0;
#else
    QStringList args;
    args << QStringLiteral("-r") << archivePath;
    for (const QString& p : paths)
        args << p;

    ok = QProcess::execute(QStringLiteral("zip"), args) == 0;
#endif

    reloadListing();

    if (ok)
        emit operationCompleted(QStringLiteral("Created archive %1").arg(QFileInfo(archivePath).fileName()));
    else
        emit operationFailed(QStringLiteral("Compression failed. On Linux/macOS, ensure zip is installed."));
}

void WorkspaceViewModel::extractSelectedItems()
{
    const QStringList paths = selectedPaths();
    if (paths.size() != 1) {
        emit operationFailed(QStringLiteral("Select exactly one archive to extract."));
        return;
    }

    const QString archivePath = paths.first();
    if (!isArchivePath(archivePath)) {
        emit operationFailed(QStringLiteral("Selected item is not a supported archive."));
        return;
    }

    bool ok = false;

#ifdef Q_OS_WINDOWS
    const QString script = QStringLiteral(
                               "Expand-Archive -LiteralPath %1 -DestinationPath %2 -Force")
                               .arg(quotePs(QDir::toNativeSeparators(archivePath)))
                               .arg(quotePs(QDir::toNativeSeparators(m_currentDirectoryPath)));

    ok = QProcess::execute(
             QStringLiteral("powershell"),
             { QStringLiteral("-NoProfile"), QStringLiteral("-Command"), script }) == 0;
#else
    const QString lower = QFileInfo(archivePath).suffix().toLower();

    if (lower == QStringLiteral("zip")) {
        ok = QProcess::execute(
                 QStringLiteral("unzip"),
                 { QStringLiteral("-o"), archivePath, QStringLiteral("-d"), m_currentDirectoryPath }) == 0;
    } else {
        ok = QProcess::execute(
                 QStringLiteral("tar"),
                 { QStringLiteral("-xf"), archivePath, QStringLiteral("-C"), m_currentDirectoryPath }) == 0;
    }
#endif

    reloadListing();

    if (ok)
        emit operationCompleted(QStringLiteral("Extracted %1").arg(QFileInfo(archivePath).fileName()));
    else
        emit operationFailed(QStringLiteral("Extraction failed. On Linux/macOS, ensure unzip/tar is installed."));
}

void WorkspaceViewModel::prepareOpenWithForRow(int row)
{
    if (!isValidRow(row)) {
        m_openWithApps.clear();
        emit openWithAppsChanged();
        return;
    }

    const QVariantMap item = fileAt(row);
    if (item.value(QStringLiteral("isDir")).toBool()) {
        m_openWithApps.clear();
        emit openWithAppsChanged();
        return;
    }

    setOpenWithAppsForPath(item.value(QStringLiteral("path")).toString());
}

void WorkspaceViewModel::prepareOpenWithForSelection()
{
    setOpenWithAppsForPath(currentSelectedFilePath());
}

bool WorkspaceViewModel::openRowWithApp(int row, const QString& appIdOrExecutable)
{
    if (!isValidRow(row))
        return false;

    const QVariantMap item = fileAt(row);
    if (item.value(QStringLiteral("isDir")).toBool())
        return false;

    const QString path = item.value(QStringLiteral("path")).toString();

    const bool ok = FileAssociationService::openWithAppId(path, appIdOrExecutable);

    if (ok)
        emit operationCompleted(QStringLiteral("Opened %1 with selected app").arg(item.value(QStringLiteral("name")).toString()));
    else
        emit operationFailed(QStringLiteral("Failed to open %1 with selected app").arg(item.value(QStringLiteral("name")).toString()));

    return ok;
}

bool WorkspaceViewModel::openSelectionWithApp(const QString& appIdOrExecutable)
{
    const QString path = currentSelectedFilePath();
    if (path.isEmpty())
        return false;

    const bool ok = FileAssociationService::openWithAppId(path, appIdOrExecutable);

    if (ok)
        emit operationCompleted(QStringLiteral("Opened file with selected app"));
    else
        emit operationFailed(QStringLiteral("Failed to open file with selected app"));

    return ok;
}

QString WorkspaceViewModel::normalizeViewMode(const QString& value) const
{
    const QString trimmed = value.trimmed();

    if (trimmed == QStringLiteral("Details"))
        return trimmed;
    if (trimmed == QStringLiteral("Tiles"))
        return trimmed;
    if (trimmed == QStringLiteral("Compact"))
        return trimmed;
    if (trimmed == QStringLiteral("Large icons"))
        return trimmed;

    return QStringLiteral("Details");
}

QString WorkspaceViewModel::iconForViewMode(const QString& mode) const
{
    if (mode == QStringLiteral("Details"))
        return QStringLiteral("detailed-view");
    if (mode == QStringLiteral("Tiles"))
        return QStringLiteral("tile-view");
    if (mode == QStringLiteral("Compact"))
        return QStringLiteral("list-view");
    if (mode == QStringLiteral("Large icons"))
        return QStringLiteral("grid-view");

    return QStringLiteral("list-view");
}

void WorkspaceViewModel::emitSelectionSignals(int previousSelected, const QString& previousItemsText, bool selectionChanged)
{
    if (previousSelected != selectedItems())
        emit selectedItemsChanged();

    if (previousItemsText != itemsText())
        emit itemsTextChanged();

    if (selectionChanged) {
        ++m_selectionRevision;
        emit selectionStateChanged();
    }
}

int WorkspaceViewModel::firstSelectedRow() const
{
    if (m_selectedRows.isEmpty())
        return -1;

    int result = -1;
    for (int row : m_selectedRows) {
        if (result < 0 || row < result)
            result = row;
    }

    return result;
}

QVariantMap WorkspaceViewModel::previewDataForRow(int row) const
{
    const QVariantMap item = fileAt(row);
    if (item.isEmpty())
        return {};

    const QString name = item.value(QStringLiteral("name")).toString();
    const QString type = item.value(QStringLiteral("type")).toString();
    const QString size = item.value(QStringLiteral("size")).toString();
    const QString dateModified = item.value(QStringLiteral("dateModified")).toString();
    const QString icon = item.value(QStringLiteral("icon")).toString();
    const QString nativeIconSource = item.value(QStringLiteral("nativeIconSource")).toString();
    const bool isDir = item.value(QStringLiteral("isDir")).toBool();
    const QString path = item.value(QStringLiteral("path")).toString();
    const QString previewType = isDir
                                    ? QStringLiteral("folder")
                                    : (icon == QStringLiteral("image")
                                           ? QStringLiteral("image")
                                           : QStringLiteral("text"));

    QVariantList lines;
    QString summary = isDir ? QStringLiteral("Folder selected.")
                            : (previewType == QStringLiteral("image")
                                   ? QStringLiteral("Image selected.")
                                   : QStringLiteral("File selected."));

    if (lines.isEmpty()) {
        lines.push_back(QStringLiteral("Name: %1").arg(name));
        lines.push_back(QStringLiteral("Path: %1").arg(path));
        lines.push_back(QStringLiteral("Type: %1").arg(type));
        lines.push_back(QStringLiteral("Modified: %1").arg(dateModified));
        if (!size.isEmpty())
            lines.push_back(QStringLiteral("Size: %1").arg(size));
    }

    QVariantMap data;
    data.insert(QStringLiteral("visible"), true);
    data.insert(QStringLiteral("name"), name);
    data.insert(QStringLiteral("type"), type);
    data.insert(QStringLiteral("icon"), icon.isEmpty() ? QStringLiteral("insert-drive-file") : icon);
    data.insert(QStringLiteral("nativeIconSource"), nativeIconSource);
    data.insert(QStringLiteral("previewType"), previewType);
    data.insert(QStringLiteral("size"), size);
    data.insert(QStringLiteral("dateModified"), dateModified);
    data.insert(QStringLiteral("summary"), summary);
    data.insert(QStringLiteral("lines"), lines);
    return data;
}

QVariantList WorkspaceViewModel::buildDraggedItems() const
{
    QVariantList result;

    QList<int> rows = m_selectedRows.values();
    std::sort(rows.begin(), rows.end());

    for (int row : rows)
        result.push_back(fileAt(row));

    return result;
}

bool WorkspaceViewModel::isValidRow(int row) const
{
    return row >= 0 && row < m_fileModel.rowCount();
}

void WorkspaceViewModel::clearDragState()
{
    const bool wasDragging = m_draggingItems;
    m_draggingItems = false;
    m_draggedItems.clear();
    m_lastDropTargetPath.clear();
    m_lastDropTargetKind.clear();

    clearDragPreview();

    if (wasDragging)
        emit draggingItemsChanged();
}

void WorkspaceViewModel::clearDragPreview()
{
    const bool hadPreview =
        m_dragPreviewVisible
        || !m_dragPreviewText.isEmpty()
        || !m_dragPreviewIcon.isEmpty()
        || !qFuzzyIsNull(m_dragPreviewX)
        || !qFuzzyIsNull(m_dragPreviewY);

    m_dragPreviewVisible = false;
    m_dragPreviewX = 0.0;
    m_dragPreviewY = 0.0;
    m_dragPreviewText.clear();
    m_dragPreviewIcon = QStringLiteral("insert-drive-file");

    if (hadPreview)
        emit dragPreviewChanged();
}

void WorkspaceViewModel::createPendingItem(bool isDir)
{
    if (m_inlineEditRow >= 0 && !commitInlineEdit())
        return;

    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;
    const int previousCurrentIndex = m_currentIndex;

    const QString defaultName = isDir
                                    ? QStringLiteral("New Folder")
                                    : QStringLiteral("New File.txt");

    const FileListModel::FileItem item = buildItemFromName(defaultName, isDir);
    m_fileModel.insertItem(0, item);
    emit totalItemsChanged();

    m_selectedRows.clear();
    m_selectedRows.insert(0);
    m_selectionAnchorRow = 0;
    m_currentIndex = 0;

    if (previousCurrentIndex != m_currentIndex)
        emit currentIndexChanged();

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);

    setInlineEditState(0, defaultName, true);
}

QString WorkspaceViewModel::validateInlineEditText(const QString& text) const
{
    if (text.isEmpty())
        return QStringLiteral("Name cannot be empty.");

    if (text == QStringLiteral(".") || text == QStringLiteral(".."))
        return QStringLiteral("This name is not allowed.");

    static const QRegularExpression invalidChars(QStringLiteral(R"([\\/:*?"<>|])"));
    if (invalidChars.match(text).hasMatch())
        return QStringLiteral("Invalid characters: \\ / : * ? \" < > |");

    if (text.endsWith(QLatin1Char(' ')) || text.endsWith(QLatin1Char('.')))
        return QStringLiteral("Name cannot end with a space or dot.");

    QString stem = text;
    const int dotIndex = stem.indexOf(QLatin1Char('.'));
    if (dotIndex > 0)
        stem = stem.left(dotIndex);

    const QString upperStem = stem.toUpper();

    static const QSet<QString> reservedNames = {
        QStringLiteral("CON"),
        QStringLiteral("PRN"),
        QStringLiteral("AUX"),
        QStringLiteral("NUL"),
        QStringLiteral("COM1"),
        QStringLiteral("COM2"),
        QStringLiteral("COM3"),
        QStringLiteral("COM4"),
        QStringLiteral("COM5"),
        QStringLiteral("COM6"),
        QStringLiteral("COM7"),
        QStringLiteral("COM8"),
        QStringLiteral("COM9"),
        QStringLiteral("LPT1"),
        QStringLiteral("LPT2"),
        QStringLiteral("LPT3"),
        QStringLiteral("LPT4"),
        QStringLiteral("LPT5"),
        QStringLiteral("LPT6"),
        QStringLiteral("LPT7"),
        QStringLiteral("LPT8"),
        QStringLiteral("LPT9")
    };

    if (reservedNames.contains(upperStem))
        return QStringLiteral("This name is reserved by Windows.");

    const QVector<FileListModel::FileItem> items = m_fileModel.items();
    for (int i = 0; i < items.size(); ++i) {
        if (i == m_inlineEditRow)
            continue;

        if (items.at(i).name.compare(text, Qt::CaseInsensitive) == 0)
            return QStringLiteral("An item with this name already exists here.");
    }

    return {};
}

FileListModel::FileItem WorkspaceViewModel::buildItemFromName(const QString& name, bool isDir) const
{
    FileListModel::FileItem item;

    QString normalizedPath = m_currentDirectoryPath;
    if (normalizedPath.endsWith('/'))
        normalizedPath.chop(1);

    item.name = name;
    item.path = normalizedPath + QStringLiteral("/") + item.name;
    item.dateModified = QDateTime::currentDateTime().toString(QStringLiteral("dd/MM/yyyy HH:mm"));
    item.isDir = isDir;
    item.lastModifiedValue = QDateTime::currentDateTime();

    if (isDir) {
        item.type = QStringLiteral("File folder");
        item.size.clear();
        item.icon = QStringLiteral("folder");
        item.nativeIconSource.clear();
        item.sizeBytes = 0;
        return item;
    }

    QFileInfo info(item.path);
    item.type = fallbackTypeFromSuffix(info);
    item.icon = iconForFileInfo(info);
    item.nativeIconSource = nativeIconSourceForFileInfo(info);
    item.size.clear();
    item.sizeBytes = 0;
    return item;
}

void WorkspaceViewModel::setInlineEditState(int row, const QString& text, bool isNew)
{
    const bool stateChanged =
        m_inlineEditRow != row
        || m_inlineEditIsNew != isNew;

    m_inlineEditRow = row;
    m_inlineEditIsNew = isNew;
    m_inlineEditText = text;
    m_inlineEditError = validateInlineEditText(text);

    ++m_inlineEditFocusToken;

    if (stateChanged)
        emit inlineEditStateChanged();

    emit inlineEditTextChanged();
    emit inlineEditErrorChanged();
    emit inlineEditFocusTokenChanged();
}

void WorkspaceViewModel::setInlineEditError(const QString& error)
{
    if (m_inlineEditError == error)
        return;

    m_inlineEditError = error;
    emit inlineEditErrorChanged();
}

void WorkspaceViewModel::clearInlineEditState()
{
    const bool hadState = m_inlineEditRow >= 0 || m_inlineEditIsNew || !m_inlineEditText.isEmpty() || !m_inlineEditError.isEmpty();

    m_inlineEditRow = -1;
    m_inlineEditIsNew = false;
    m_inlineEditText.clear();
    m_inlineEditError.clear();

    if (hadState) {
        emit inlineEditStateChanged();
        emit inlineEditTextChanged();
        emit inlineEditErrorChanged();
    }
}

QString WorkspaceViewModel::normalizePath(QString value) const
{
    value = value.trimmed();
    if (value.isEmpty())
        return {};

    value.replace('\\', '/');

    if (value.startsWith(QStringLiteral("container://")))
        return {};

#ifdef Q_OS_WINDOWS
    const bool isUncPath =
        value.startsWith(QStringLiteral("//"))
        && !value.startsWith(QStringLiteral("///"));

    if (isUncPath) {
        QString tail = value.mid(2);
        while (tail.contains(QStringLiteral("//")))
            tail.replace(QStringLiteral("//"), QStringLiteral("/"));

        return QStringLiteral("//") + tail;
    }

    static const QRegularExpression driveOnlyRe(QStringLiteral("^([A-Za-z]:)$"));
    static const QRegularExpression driveRootRe(QStringLiteral("^([A-Za-z]:)/$"));

    QRegularExpressionMatch m = driveOnlyRe.match(value);
    if (m.hasMatch())
        return m.captured(1) + QStringLiteral("/");

    m = driveRootRe.match(value);
    if (m.hasMatch())
        return m.captured(1) + QStringLiteral("/");
#endif

    while (value.contains(QStringLiteral("//")))
        value.replace(QStringLiteral("//"), QStringLiteral("/"));

    return QDir::fromNativeSeparators(QFileInfo(value).absoluteFilePath());
}

QString WorkspaceViewModel::parentLocationForPath(const QString& path) const
{
    const QFileInfo info(normalizePath(path));
    return normalizePath(info.dir().absolutePath());
}

QString WorkspaceViewModel::childLocationForName(const QString& directoryPath, const QString& name) const
{
    return normalizePath(QDir(normalizePath(directoryPath)).filePath(name));
}

QString WorkspaceViewModel::uniqueLocationInDirectory(const QString& directoryPath,
                                                      const QString& originalName) const
{
    return uniquePathInDirectory(normalizePath(directoryPath), originalName);
}

QString WorkspaceViewModel::normalizeSortField(const QString& value) const
{
    const QString trimmed = value.trimmed();
    if (trimmed == QStringLiteral("dateModified")
        || trimmed == QStringLiteral("type")
        || trimmed == QStringLiteral("size")) {
        return trimmed;
    }
    return QStringLiteral("name");
}

void WorkspaceViewModel::applySort(QVector<FileListModel::FileItem>& items) const
{
    std::sort(items.begin(), items.end(), [this](const auto& left, const auto& right) {
        if (left.isDir != right.isDir)
            return left.isDir && !right.isDir;

        const int comparison = compareItemsByField(left, right, m_sortField);
        if (comparison == 0)
            return false;

        return m_sortDescending ? (comparison > 0) : (comparison < 0);
    });
}

void WorkspaceViewModel::loadLocation(const QString& path, bool pushHistory)
{
    const QString normalized = normalizePath(path);
    if (normalized.isEmpty())
        return;

    QFileInfo info(normalized);
    if (!info.exists() || !info.isDir())
        return;

    if (m_currentDirectoryPath != normalized) {
        m_currentDirectoryPath = normalized;
        emit currentDirectoryPathChanged();
    }

    if (pushHistory) {
        if (m_historyIndex >= 0 && m_historyIndex < m_history.size() - 1)
            m_history = m_history.mid(0, m_historyIndex + 1);

        if (m_history.isEmpty() || m_history.last() != normalized) {
            m_history.push_back(normalized);
            m_historyIndex = m_history.size() - 1;
        } else {
            m_historyIndex = m_history.size() - 1;
        }
    }

    reloadListing();
}

void WorkspaceViewModel::reloadListing()
{
    const QStringList previousPaths = selectedPaths();
    const QString previousCurrentPath =
        isValidRow(m_currentIndex)
            ? fileAt(m_currentIndex).value(QStringLiteral("path")).toString()
            : QString();

    QVector<FileListModel::FileItem> items;

    if (m_activeSearch.isEmpty())
        items = listDirectoryItems(m_currentDirectoryPath);
    else
        items = searchItems(m_currentDirectoryPath, m_activeSearch, m_activeSearchScope);

    m_fileModel.setItems(items);

    emit totalItemsChanged();
    if (!restoreSelectionToPaths(previousPaths, previousCurrentPath))
        resetSelectionToFirstItem();
}

QVector<FileListModel::FileItem> WorkspaceViewModel::listDirectoryItems(const QString& path)
{
    QVector<FileListModel::FileItem> result;

    QDir dir(path);
    if (!dir.exists())
        return result;

    QDir::Filters filters = QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Readable;
    if (m_settings.showHiddenFiles())
        filters |= (QDir::Hidden | QDir::System);

    const QFileInfoList entries = dir.entryInfoList(
        filters,
        QDir::NoSort);

    result.reserve(entries.size());
    for (const QFileInfo& info : entries) {
        if (!shouldIncludeInfo(info, m_settings.showHiddenFiles()))
            continue;

        result.push_back(buildItemFromInfo(info));
    }

    applySort(result);
    return result;
}

QVector<FileListModel::FileItem> WorkspaceViewModel::searchItems(const QString& basePath,
                                                                 const QString& query,
                                                                 const QString& scope)
{
    QVector<FileListModel::FileItem> result;
    const QString trimmedQuery = query.trimmed();
    if (trimmedQuery.isEmpty())
        return listDirectoryItems(basePath);

    if (scope == QStringLiteral("global")) {
        QDirIterator::IteratorFlags flags = QDirIterator::Subdirectories;

        QDir::Filters filters = QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Readable;
        if (m_settings.showHiddenFiles())
            filters |= (QDir::Hidden | QDir::System);

        QDirIterator it(basePath, filters, flags);

        while (it.hasNext()) {
            it.next();
            const QFileInfo info = it.fileInfo();

            if (!shouldIncludeInfo(info, m_settings.showHiddenFiles()))
                continue;

            if (displayNameForFileInfo(info).contains(trimmedQuery, Qt::CaseInsensitive)
                || info.fileName().contains(trimmedQuery, Qt::CaseInsensitive)) {
                result.push_back(buildItemFromInfo(info));
            }
        }
    } else {
        const QVector<FileListModel::FileItem> all = listDirectoryItems(basePath);
        for (const FileListModel::FileItem& item : all) {
            if (item.name.contains(trimmedQuery, Qt::CaseInsensitive))
                result.push_back(item);
        }
    }

    applySort(result);
    return result;
}

void WorkspaceViewModel::resetSelectionToFirstItem()
{
    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;
    const int previousCurrentIndex = m_currentIndex;

    m_selectedRows.clear();

    if (m_fileModel.rowCount() > 0) {
        m_currentIndex = 0;
        m_selectionAnchorRow = 0;
        m_selectedRows.insert(0);
    } else {
        m_currentIndex = -1;
        m_selectionAnchorRow = -1;
    }

    if (previousCurrentIndex != m_currentIndex)
        emit currentIndexChanged();

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
}

bool WorkspaceViewModel::restoreSelectionToPaths(const QStringList& paths, const QString& currentPath)
{
    if (paths.isEmpty())
        return false;

    QSet<QString> remainingPaths;
    for (const QString& path : paths)
        remainingPaths.insert(normalizePath(path));

    if (remainingPaths.isEmpty())
        return false;

    const int previousSelected = selectedItems();
    const QString previousItemsText = itemsText();
    const QSet<int> previousRows = m_selectedRows;
    const int previousCurrentIndex = m_currentIndex;

    QList<int> matchedRows;
    int nextCurrentIndex = -1;
    const QString normalizedCurrentPath = normalizePath(currentPath);

    for (int row = 0; row < m_fileModel.rowCount(); ++row) {
        const QString rowPath = normalizePath(fileAt(row).value(QStringLiteral("path")).toString());
        if (!remainingPaths.contains(rowPath))
            continue;

        matchedRows.push_back(row);
        if (!normalizedCurrentPath.isEmpty()
            && rowPath.compare(normalizedCurrentPath, Qt::CaseInsensitive) == 0) {
            nextCurrentIndex = row;
        }
    }

    if (matchedRows.isEmpty())
        return false;

    m_selectedRows.clear();
    for (int row : matchedRows)
        m_selectedRows.insert(row);
    m_selectionAnchorRow = matchedRows.first();
    m_currentIndex = nextCurrentIndex >= 0 ? nextCurrentIndex : matchedRows.first();

    if (previousCurrentIndex != m_currentIndex)
        emit currentIndexChanged();

    emitSelectionSignals(previousSelected, previousItemsText, previousRows != m_selectedRows);
    return true;
}

QVariantList WorkspaceViewModel::selectedItemsAsMaps() const
{
    QVariantList result;
    QList<int> rows = m_selectedRows.values();
    std::sort(rows.begin(), rows.end());
    for (int row : rows)
        result.push_back(fileAt(row));
    return result;
}

QStringList WorkspaceViewModel::selectedPaths() const
{
    QStringList out;
    const QVariantList items = selectedItemsAsMaps();
    for (const QVariant& value : items) {
        const QString path = value.toMap().value(QStringLiteral("path")).toString();
        if (!path.isEmpty())
            out.push_back(path);
    }
    return out;
}

QString WorkspaceViewModel::currentSelectedFilePath() const
{
    if (m_selectedRows.size() != 1)
        return {};

    const QVariantMap item = fileAt(firstSelectedRow());
    if (item.value(QStringLiteral("isDir")).toBool())
        return {};

    return item.value(QStringLiteral("path")).toString();
}

void WorkspaceViewModel::setOpenWithAppsForPath(const QString& filePath)
{
    QVariantList out;

    if (!filePath.trimmed().isEmpty()) {
        const QList<FileAssociationService::AssociatedApp> apps = FileAssociationService::appsForFile(filePath);
        for (const auto& app : apps) {
            QVariantMap map;
            map.insert(QStringLiteral("id"), !app.id.isEmpty() ? app.id : app.executable);
            map.insert(QStringLiteral("name"), app.name);
            map.insert(QStringLiteral("executable"), app.executable);
            map.insert(QStringLiteral("command"), app.command);
            map.insert(QStringLiteral("isDefault"), app.isDefault);
            out.push_back(map);
        }
    }

    m_openWithApps = out;
    emit openWithAppsChanged();
}

void WorkspaceViewModel::selectPathIfVisible(const QString& path)
{
    const QString normalizedTarget = normalizePath(path);
    if (normalizedTarget.isEmpty())
        return;

    for (int row = 0; row < m_fileModel.rowCount(); ++row) {
        const QString rowPath = normalizePath(fileAt(row).value(QStringLiteral("path")).toString());
        if (rowPath.compare(normalizedTarget, Qt::CaseInsensitive) == 0) {
            selectOnlyRow(row);
            return;
        }
    }
}

void WorkspaceViewModel::copySelectedPathTextToClipboard()
{
    const QStringList paths = selectedPaths();
    if (paths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing selected."));
        return;
    }

    if (QGuiApplication::clipboard())
        QGuiApplication::clipboard()->setText(paths.join(QLatin1Char('\n')));

    emit operationCompleted(
        paths.size() == 1
            ? QStringLiteral("Copied path")
            : QStringLiteral("Copied %1 paths").arg(paths.size()));
}

void WorkspaceViewModel::openContainingFolderForSelection()
{
    const int row = firstSelectedRow();
    if (row < 0 || !isValidRow(row)) {
        emit operationFailed(QStringLiteral("No item selected."));
        return;
    }

    const QVariantMap item = fileAt(row);
    const QString itemPath = item.value(QStringLiteral("path")).toString();
    const QString parentPath = parentLocationForPath(itemPath);
    if (parentPath.isEmpty()) {
        emit operationFailed(QStringLiteral("Containing folder is unavailable."));
        return;
    }

    loadLocation(parentPath, true);
    selectPathIfVisible(itemPath);
    emit operationCompleted(
        QStringLiteral("Opened containing folder for %1").arg(item.value(QStringLiteral("name")).toString()));
}

void WorkspaceViewModel::emitPropertiesForItem(const QVariantMap& item)
{
    const QString name = item.value(QStringLiteral("name")).toString().trimmed();
    emit contextInfoRequested(
        QStringLiteral("Properties: %1").arg(name.isEmpty() ? QStringLiteral("Item") : name),
        buildPropertiesDetails(item),
        QStringLiteral("info"));
}

QString WorkspaceViewModel::buildPropertiesDetails(const QVariantMap& item) const
{
    const QString path = item.value(QStringLiteral("path")).toString();

    QFileInfo info(path);

    QStringList lines;
    lines.push_back(QStringLiteral("Path: %1").arg(QDir::toNativeSeparators(path)));
    lines.push_back(QStringLiteral("Type: %1").arg(item.value(QStringLiteral("type")).toString()));

    if (info.exists()) {
        if (info.isDir()) {
            const QDir dir(path);
            const QFileInfoList entries = dir.entryInfoList(
                QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
            lines.push_back(QStringLiteral("Items: %1").arg(entries.size()));
            lines.push_back(QStringLiteral("Size: %1").arg(formatBytes(totalBytesForPath(path))));
        } else {
            lines.push_back(QStringLiteral("Size: %1").arg(formatBytes(info.size())));
        }

        const QDateTime created = info.birthTime();
        if (created.isValid())
            lines.push_back(QStringLiteral("Created: %1").arg(QLocale().toString(created, QLocale::ShortFormat)));

        const QDateTime modified = info.lastModified();
        if (modified.isValid())
            lines.push_back(QStringLiteral("Modified: %1").arg(QLocale().toString(modified, QLocale::ShortFormat)));

        const QDateTime accessed = info.lastRead();
        if (accessed.isValid())
            lines.push_back(QStringLiteral("Accessed: %1").arg(QLocale().toString(accessed, QLocale::ShortFormat)));

        const QString owner = info.owner();
        if (!owner.isEmpty())
            lines.push_back(QStringLiteral("Owner: %1").arg(owner));

        const QString group = info.group();
        if (!group.isEmpty())
            lines.push_back(QStringLiteral("Group: %1").arg(group));

        lines.push_back(QStringLiteral("Permissions: %1").arg(permissionsToString(info.permissions())));

        if (info.isSymLink())
            lines.push_back(QStringLiteral("Target: %1").arg(QDir::toNativeSeparators(info.symLinkTarget())));
    } else {
        lines.push_back(QStringLiteral("Status: Item is no longer available on disk."));
    }

    return lines.join(QLatin1Char('\n'));
}