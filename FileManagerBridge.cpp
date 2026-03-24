#include "FileManagerBridge.h"

#include "FileManagerSessionService.h"
#include "FileManagerNavigationService.h"
#include "FileManagerFileOpsService.h"
#include "FileManagerSearchService.h"
#include "FileManagerSidebarService.h"

#include <QStringList>
#include <QOperatingSystemVersion>
#include <QRegularExpression>
#include <QStringView>
#include <QClipboard>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QGuiApplication>
#include <QStandardPaths>

FileManagerBridge::FileManagerBridge(QObject* parent)
    : QObject(parent)
    , m_sessionService(new FileManagerSessionService(this))
    , m_navigationService(new FileManagerNavigationService(this))
    , m_fileOpsService(new FileManagerFileOpsService(this))
    , m_searchService(new FileManagerSearchService(this))
    , m_sidebarService(new FileManagerSidebarService(this))
{
    qDebug() << "Run on startup";

    m_previewEnabled = m_appSettings.previewEnabled();
    m_showHiddenFiles = m_appSettings.showHiddenFiles();
    m_currentFileRow = -1;

    m_fileOpsService->reloadForPath(m_navigationService->pathText());
}

FileManagerBridge::~FileManagerBridge() = default;

QVariantMap FileManagerBridge::makeSnapshot(const QString& message,
                                            const QString& messageKind) const
{
    QVariantMap out;
    out.insert(QStringLiteral("currentTab"), m_sessionService->currentTabIndex());
    out.insert(QStringLiteral("tabs"), m_sessionService->tabs());
    out.insert(QStringLiteral("path"), m_navigationService->pathParts());
    out.insert(QStringLiteral("pathText"), m_navigationService->pathText());
    out.insert(QStringLiteral("files"), m_fileOpsService->files());
    out.insert(QStringLiteral("drives"), m_sidebarService->drives());
    out.insert(QStringLiteral("sidebar"), m_sidebarService->sidebarTree());

    out.insert(QStringLiteral("theme"), m_appSettings.theme());
    out.insert(QStringLiteral("searchScope"), m_appSettings.searchScope());
    out.insert(QStringLiteral("viewMode"), m_appSettings.viewMode());
    out.insert(QStringLiteral("previewEnabled"), m_previewEnabled);
    out.insert(QStringLiteral("showHiddenFiles"), m_showHiddenFiles);

    out.insert(QStringLiteral("message"), message);
    out.insert(QStringLiteral("messageKind"),
               messageKind.isEmpty() ? QStringLiteral("info") : messageKind);
    return out;
}

QVariantList FileManagerBridge::normalizeItems(const QVariantList& items) const
{
    QVariantList out;

    for (const QVariant& item : items) {
        if (item.metaType().id() == QMetaType::QVariantMap) {
            const QVariantMap map = item.toMap();
            if (map.contains(QStringLiteral("row"))) {
                out.append(map);
            }
        } else if (item.canConvert<int>()) {
            QVariantMap map;
            map.insert(QStringLiteral("row"), item.toInt());
            out.append(map);
        }
    }

    return out;
}

QVariantList FileManagerBridge::rowsFromItems(const QVariantList& items) const
{
    QVariantList out;
    const QVariantList normalized = normalizeItems(items);

    for (const QVariant& itemVar : normalized) {
        const QVariantMap item = itemVar.toMap();
        if (item.contains(QStringLiteral("row")))
            out.append(item.value(QStringLiteral("row")).toInt());
    }

    return out;
}

QVariantList FileManagerBridge::singleRowItemList(int row) const
{
    QVariantList out;
    QVariantMap item;
    item.insert(QStringLiteral("row"), row);
    out.append(item);
    return out;
}

QString FileManagerBridge::describeItemCount(const QVariantList& items) const
{
    const int count = normalizeItems(items).size();
    if (count == 1)
        return QStringLiteral("1 item");
    return QString::number(count) + QStringLiteral(" items");
}

bool FileManagerBridge::isValidFileName(const QString& name, QString* error) const
{
    const QString trimmed = name.trimmed();

    if (trimmed.isEmpty()) {
        if (error)
            *error = QStringLiteral("Name cannot be empty");
        return false;
    }

    if (trimmed == QStringLiteral(".") || trimmed == QStringLiteral("..")) {
        if (error)
            *error = QStringLiteral("Name is not valid");
        return false;
    }

    static const QRegularExpression invalidChars(QStringLiteral(R"([<>:"/\\|?*\x00-\x1F])"));
    if (invalidChars.match(trimmed).hasMatch()) {
        if (error)
            *error = QStringLiteral("Name contains invalid filesystem characters");
        return false;
    }

    if (trimmed.endsWith(QLatin1Char(' ')) || trimmed.endsWith(QLatin1Char('.'))) {
        if (error)
            *error = QStringLiteral("Name cannot end with a space or dot");
        return false;
    }

    const QString upper = trimmed.toUpper();
    static const QStringList reservedNames = {
        QStringLiteral("CON"), QStringLiteral("PRN"), QStringLiteral("AUX"), QStringLiteral("NUL"),
        QStringLiteral("COM1"), QStringLiteral("COM2"), QStringLiteral("COM3"), QStringLiteral("COM4"),
        QStringLiteral("COM5"), QStringLiteral("COM6"), QStringLiteral("COM7"), QStringLiteral("COM8"),
        QStringLiteral("COM9"),
        QStringLiteral("LPT1"), QStringLiteral("LPT2"), QStringLiteral("LPT3"), QStringLiteral("LPT4"),
        QStringLiteral("LPT5"), QStringLiteral("LPT6"), QStringLiteral("LPT7"), QStringLiteral("LPT8"),
        QStringLiteral("LPT9")
    };

    const QString basePart = upper.section(QLatin1Char('.'), 0, 0);
    if (reservedNames.contains(basePart)) {
        if (error)
            *error = QStringLiteral("Name is reserved by the filesystem");
        return false;
    }

    if (trimmed.size() > 255) {
        if (error)
            *error = QStringLiteral("Name is too long");
        return false;
    }

    return true;
}

bool FileManagerBridge::isValidPathText(const QString& pathText, QString* error) const
{
    const QString trimmed = pathText.trimmed();

    if (trimmed.isEmpty()) {
        if (error)
            *error = QStringLiteral("Path cannot be empty");
        return false;
    }

    static const QRegularExpression invalidChars(QStringLiteral(R"([<>\"|?*\x00-\x1F])"));
    if (invalidChars.match(trimmed).hasMatch()) {
        if (error)
            *error = QStringLiteral("Path contains invalid filesystem characters");
        return false;
    }

    return true;
}

QVariantMap FileManagerBridge::validateFileName(const QString& name) const
{
    QString error;
    const bool ok = isValidFileName(name, &error);

    QVariantMap out;
    out.insert(QStringLiteral("ok"), ok);
    out.insert(QStringLiteral("message"),
               ok ? QStringLiteral("[Backend] Name is valid")
                  : QStringLiteral("[Backend] ") + error);
    out.insert(QStringLiteral("messageKind"), ok ? QStringLiteral("success")
                                                 : QStringLiteral("error"));
    return out;
}

QVariantMap FileManagerBridge::bootstrap()
{
    return makeSnapshot(QStringLiteral("[Backend] Bootstrap complete"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::activateTab(int index)
{
    m_sessionService->activateTab(index);
    return makeSnapshot(QStringLiteral("[Backend] Activated tab"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::addTab(const QString& title)
{
    m_sessionService->addTab(title);
    return makeSnapshot(QStringLiteral("[Backend] Opened new tab"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::duplicateTab(int index)
{
    m_sessionService->duplicateTab(index);
    return makeSnapshot(QStringLiteral("[Backend] Duplicated tab"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::closeTab(int index)
{
    m_sessionService->closeTab(index);
    return makeSnapshot(QStringLiteral("[Backend] Closed tab"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::renameTab(int index, const QString& title)
{
    m_sessionService->renameTab(index, title.trimmed());
    return makeSnapshot(QStringLiteral("[Backend] Renamed tab"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::moveTab(int from, int to)
{
    m_sessionService->moveTab(from, to);
    return makeSnapshot(QStringLiteral("[Backend] Reordered tabs"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::navigateToPathString(const QString& pathText)
{
    m_navigationService->navigateToPathString(pathText);
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Navigated to path"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::navigateToPathParts(const QVariantList& parts)
{
    m_navigationService->navigateToPathParts(parts);
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Navigated via breadcrumb"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openSidebarLocation(const QString& label,
                                                   const QString& icon,
                                                   const QString& kind)
{
    Q_UNUSED(icon);
    m_navigationService->openSidebarLocation(label, kind);
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Opened sidebar location"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::goBack()
{
    m_navigationService->goBack();
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Went back"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::goForward()
{
    m_navigationService->goForward();
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Went forward"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::goUp()
{
    m_navigationService->goUp();
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Went up"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::refresh()
{
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Refreshed"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::openItems(const QVariantList& items)
{
    const QVariantList rows = rowsFromItems(items);
    if (rows.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to open"), QStringLiteral("info"));

    if (rows.size() == 1) {
        const int row = rows.first().toInt();
        const QVariantMap item = m_fileOpsService->fileAt(row);

        if (item.value(QStringLiteral("type")).toString() == QStringLiteral("File folder")) {
            m_navigationService->appendPathSegment(item.value(QStringLiteral("name")).toString());
            m_fileOpsService->reloadForPath(m_navigationService->pathText());
            return makeSnapshot(QStringLiteral("[Backend] Opened folder"), QStringLiteral("info"));
        }

        return makeSnapshot(QStringLiteral("[Backend] Opened item"), QStringLiteral("info"));
    }

    return makeSnapshot(QStringLiteral("[Backend] Opened ") + describeItemCount(items), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openItemsInNewTab(const QVariantList& items)
{
    const QVariantList rows = rowsFromItems(items);
    if (rows.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to open in new tab"),
                            QStringLiteral("info"));

    const int row = rows.first().toInt();
    const QVariantMap item = m_fileOpsService->fileAt(row);
    if (item.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] Invalid item for new tab"),
                            QStringLiteral("error"));

    const QString title = item.value(QStringLiteral("name")).toString().isEmpty()
                              ? QStringLiteral("New Tab")
                              : item.value(QStringLiteral("name")).toString();

    m_sessionService->addTab(title);

    const QString type = item.value(QStringLiteral("type")).toString();
    if (type == QStringLiteral("File folder")) {
        m_navigationService->appendPathSegment(item.value(QStringLiteral("name")).toString());
        m_fileOpsService->reloadForPath(m_navigationService->pathText());
        return makeSnapshot(QStringLiteral("[Backend] Opened folder in new tab"),
                            QStringLiteral("success"));
    }

    return makeSnapshot(QStringLiteral("[Backend] Opened item in new tab"),
                        QStringLiteral("success"));
}

QVariantMap FileManagerBridge::createFile()
{
    m_fileOpsService->createFile();
    return makeSnapshot(QStringLiteral("[Backend] Created file"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::createFolder()
{
    m_fileOpsService->createFolder();
    return makeSnapshot(QStringLiteral("[Backend] Created folder"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::renameItems(const QVariantList& items, const QString& newName)
{
    const QVariantList rows = rowsFromItems(items);
    if (rows.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to rename"), QStringLiteral("info"));

    if (rows.size() != 1)
        return makeSnapshot(QStringLiteral("[Backend] Rename requires exactly 1 item"), QStringLiteral("info"));

    QString error;
    if (!isValidFileName(newName, &error))
        return makeSnapshot(QStringLiteral("[Backend] ") + error, QStringLiteral("error"));

    m_fileOpsService->renameRow(rows.first().toInt(), newName.trimmed());
    return makeSnapshot(QStringLiteral("[Backend] Renamed item"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::deleteItems(const QVariantList& items)
{
    const QVariantList rows = rowsFromItems(items);
    if (rows.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to delete"), QStringLiteral("info"));

    m_fileOpsService->deleteRows(rows);
    return makeSnapshot(QStringLiteral("[Backend] Deleted ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::moveItems(const QVariantList& items,
                                         const QString& targetLabel,
                                         const QString& targetKind)
{
    const QVariantList rows = rowsFromItems(items);
    if (rows.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to move"), QStringLiteral("info"));

    m_fileOpsService->moveRows(rows, targetLabel, targetKind);
    return makeSnapshot(QStringLiteral("[Backend] Moved ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::copyItems(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to copy"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Copied ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::cutItems(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to cut"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Cut ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::pasteItems()
{
    return pasteItems(QString(), QString());
}

QVariantMap FileManagerBridge::pasteItems(const QString& targetLabel,
                                          const QString& targetKind)
{
    Q_UNUSED(targetLabel);
    Q_UNUSED(targetKind);
    return makeSnapshot(QStringLiteral("[Backend] Pasted items"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::duplicateItems(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to duplicate"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Duplicated ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::compressItems(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to compress"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Compressed ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::extractItems(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to extract"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Extracted ") + describeItemCount(items), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::showProperties(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items for properties"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Opened properties for ") + describeItemCount(items),
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::showItemProperties(const QVariantList& items)
{
    return showProperties(items);
}

QVariantMap FileManagerBridge::showCurrentLocationProperties()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened current location properties"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openItemsWith(const QVariantList& items, const QString& appName)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to open with app"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Opened ") + describeItemCount(items)
                            + QStringLiteral(" with ") + appName,
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::chooseOpenWithApp(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No items to choose app for"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Open-with picker opened for ") + describeItemCount(items),
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::copyItemPaths(const QVariantList& items,
                                             bool relativeToCurrentDir,
                                             bool recursive)
{
    const QVariantList rows = rowsFromItems(items);
    if (rows.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No item paths to copy"), QStringLiteral("info"));

    QStringList lines;
    for (const QVariant& rowVar : rows) {
        const QVariantMap item = m_fileOpsService->fileAt(rowVar.toInt());
        const QString absolutePath = absolutePathForItem(item);
        lines.append(collectedPathsForAbsolutePath(absolutePath,
                                                   relativeToCurrentDir,
                                                   recursive));
    }

    lines.removeDuplicates();

    if (lines.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No item paths to copy"), QStringLiteral("info"));

    copyTextToClipboard(lines.join(QLatin1Char('\n')));

    const QString mode = relativeToCurrentDir
                             ? QStringLiteral("relative")
                             : QStringLiteral("full");
    const QString recursion = recursive
                                  ? QStringLiteral(" recursively")
                                  : QString();

    return makeSnapshot(QStringLiteral("[Backend] Copied %1 %2 paths%3")
                            .arg(QString::number(lines.size()), mode, recursion),
                        QStringLiteral("success"));
}

QVariantMap FileManagerBridge::copySidebarPath(const QString& label, const QString& kind)
{
    const QString path = sidebarPathForLabel(label, kind);
    if (path.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No sidebar path to copy"), QStringLiteral("info"));

    copyTextToClipboard(path);
    return makeSnapshot(QStringLiteral("[Backend] Copied sidebar path"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::copyBreadcrumbPath(int index)
{
    const QVariantList parts = m_navigationService->pathParts();
    if (index < 0 || index >= parts.size())
        return makeSnapshot(QStringLiteral("[Backend] Invalid breadcrumb path"), QStringLiteral("error"));

    const QString path = pathFromParts(parts, index);
    if (path.isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No breadcrumb path to copy"), QStringLiteral("info"));

    copyTextToClipboard(path);
    return makeSnapshot(QStringLiteral("[Backend] Copied breadcrumb path"), QStringLiteral("success"));
}

QVariantMap FileManagerBridge::openItemsInTerminal(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No item location to open in terminal"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Opened terminal for ") + describeItemCount(items),
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::pinSidebarLocation(const QString& label, const QString& kind)
{
    Q_UNUSED(kind);

    if (label.trimmed().isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No sidebar location to pin"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Pinned ") + label, QStringLiteral("success"));
}

QVariantMap FileManagerBridge::showSidebarLocationProperties(const QString& label, const QString& kind)
{
    Q_UNUSED(kind);

    if (label.trimmed().isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No sidebar location for properties"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Opened properties for ") + label,
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::search(const QString& query, const QString& scope)
{
    m_searchService->search(query, scope);
    return makeSnapshot(QStringLiteral("[Backend] Search complete"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::setSearchScope(const QString& scope)
{
    m_appSettings.setSearchScope(scope);

    QVariantMap snapshot = makeSnapshot(
        QStringLiteral("[Backend] Search scope set to ") + m_appSettings.searchScope(),
        QStringLiteral("info"));

    snapshot.insert(QStringLiteral("searchScope"), m_appSettings.searchScope());
    return snapshot;
}

QVariantMap FileManagerBridge::setViewMode(const QString& viewMode)
{
    m_appSettings.setViewMode(viewMode);

    QVariantMap snapshot = makeSnapshot(
        QStringLiteral("[Backend] View mode set to ") + m_appSettings.viewMode(),
        QStringLiteral("info"));

    snapshot.insert(QStringLiteral("viewMode"), m_appSettings.viewMode());
    return snapshot;
}

QVariantMap FileManagerBridge::openFolderByRow(int row)
{
    return openItems(singleRowItemList(row));
}

QVariantMap FileManagerBridge::renameRow(int row, const QString& newName)
{
    return renameItems(singleRowItemList(row), newName);
}

QVariantMap FileManagerBridge::deleteRow(int row)
{
    return deleteItems(singleRowItemList(row));
}

QVariantMap FileManagerBridge::deleteRows(const QVariantList& rows)
{
    return deleteItems(rows);
}

QVariantMap FileManagerBridge::moveRows(const QVariantList& rows,
                                        const QString& targetLabel,
                                        const QString& targetKind)
{
    return moveItems(rows, targetLabel, targetKind);
}

QVariantMap FileManagerBridge::commitPathText(const QString& pathText)
{
    QString error;
    if (!isValidPathText(pathText, &error))
        return makeSnapshot(QStringLiteral("[Backend] ") + error, QStringLiteral("error"));

    m_navigationService->navigateToPathString(pathText);
    m_fileOpsService->reloadForPath(m_navigationService->pathText());
    return makeSnapshot(QStringLiteral("[Backend] Navigated to path"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::commitSearchText(const QString& query, const QString& scope)
{
    m_searchService->search(query, scope);
    return makeSnapshot(QStringLiteral("[Backend] Search complete"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openItemByRow(int row)
{
    return openItems(singleRowItemList(row));
}

QVariantMap FileManagerBridge::openItemInNewTabByRow(int row)
{
    return openItemsInNewTab(singleRowItemList(row));
}

QVariantMap FileManagerBridge::createFileAndBeginRename()
{
    m_fileOpsService->createFile();

    QVariantMap out = makeSnapshot(QStringLiteral("[Backend] Created file"), QStringLiteral("success"));
    out.insert(QStringLiteral("beginRenameRow"), 0);
    return out;
}

QVariantMap FileManagerBridge::createFolderAndBeginRename()
{
    m_fileOpsService->createFolder();

    QVariantMap out = makeSnapshot(QStringLiteral("[Backend] Created folder"), QStringLiteral("success"));
    out.insert(QStringLiteral("beginRenameRow"), 0);
    return out;
}

QVariantMap FileManagerBridge::cutSelection(const QVariantList& items)
{
    return cutItems(items);
}

QVariantMap FileManagerBridge::copySelection(const QVariantList& items)
{
    return copyItems(items);
}

QVariantMap FileManagerBridge::deleteSelection(const QVariantList& items)
{
    return deleteItems(items);
}

QString FileManagerBridge::currentPlatform() const
{
#if defined(Q_OS_WIN)
    return QStringLiteral("windows");
#elif defined(Q_OS_MACOS)
    return QStringLiteral("macos");
#elif defined(Q_OS_LINUX)
    return QStringLiteral("linux");
#else
    return QStringLiteral("unknown");
#endif
}

QString FileManagerBridge::invalidNameCharacters() const
{
#if defined(Q_OS_WIN)
    // Windows forbids these in file/folder names
    return QStringLiteral("\\/:*?\"<>|");
#elif defined(Q_OS_MACOS)
    // Modern macOS/APFS effectively forbids slash in path component names.
    // Historically colon mattered in old APIs, but slash is the real one to block for UI naming.
    return QStringLiteral("/");
#elif defined(Q_OS_LINUX)
    // POSIX path component restriction
    return QStringLiteral("/");
#else
    // safest common subset
    return QStringLiteral("\\/:*?\"<>|");
#endif
}

bool FileManagerBridge::isValidFileOrFolderName(const QString& name) const
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
        return false;

    if (trimmed == QStringLiteral(".") || trimmed == QStringLiteral(".."))
        return false;

    if (trimmed.contains(QChar(u'\0')))
        return false;

#if defined(Q_OS_WIN)
    static const QString invalid = QStringLiteral("\\/:*?\"<>|");
    for (const QChar ch : invalid) {
        if (trimmed.contains(ch))
            return false;
    }

    // Windows disallows trailing space or dot
    if (trimmed.endsWith(u' ') || trimmed.endsWith(u'.'))
        return false;

    // Windows reserved device names
    const QString upper = trimmed.toUpper();
    static const QStringList reserved = {
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

    const QString base = upper.section(u'.', 0, 0);
    if (reserved.contains(base))
        return false;

#elif defined(Q_OS_MACOS)
    if (trimmed.contains(u'/'))
        return false;

#elif defined(Q_OS_LINUX)
    if (trimmed.contains(u'/'))
        return false;
#endif

    return true;
}

QString FileManagerBridge::sanitizeFileOrFolderName(const QString& name) const
{
    QString out = name;

    out.remove(QChar(u'\0'));

#if defined(Q_OS_WIN)
    static const QString invalid = QStringLiteral("\\/:*?\"<>|");
    for (const QChar ch : invalid)
        out.replace(ch, QChar(u'_'));

    while (out.endsWith(u' ') || out.endsWith(u'.'))
        out.chop(1);

    const QString upperBase = out.trimmed().toUpper().section(u'.', 0, 0);
    static const QStringList reserved = {
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

    if (reserved.contains(upperBase))
        out.prepend(QStringLiteral("_"));

#else
    out.replace(u'/', u'_');
#endif

    out = out.trimmed();

    if (out.isEmpty() || out == QStringLiteral(".") || out == QStringLiteral(".."))
        out = QStringLiteral("untitled");

    return out;
}

QString FileManagerBridge::normalizedClipboardPath(const QString& path) const
{
    QString out = QDir::fromNativeSeparators(path.trimmed());
    const bool isDriveRoot =
        QRegularExpression(QStringLiteral(R"(^[A-Za-z]:/?$)")).match(out).hasMatch();

    out = QDir::cleanPath(out);

    if (isDriveRoot && !out.endsWith(QLatin1Char('/')))
        out.append(QLatin1Char('/'));

    return out;
}

QString FileManagerBridge::currentDirectoryPath() const
{
    return normalizedClipboardPath(m_navigationService->pathText());
}

QString FileManagerBridge::pathFromParts(const QVariantList& parts, int endIndexInclusive) const
{
    if (parts.isEmpty())
        return QString();

    const int lastIndex =
        endIndexInclusive < 0 ? (parts.size() - 1)
                              : qMin(endIndexInclusive, parts.size() - 1);

    QStringList labels;
    for (int i = 0; i <= lastIndex; ++i) {
        const QVariantMap part = parts.at(i).toMap();
        const QString label = part.value(QStringLiteral("label")).toString();
        if (!label.isEmpty())
            labels.append(label);
    }

    if (labels.isEmpty())
        return QString();

    const QString first = labels.first();
    QString out;

    if (QRegularExpression(QStringLiteral(R"(^[A-Za-z]:$)")).match(first).hasMatch()) {
        out = first + QLatin1Char('/');
        if (labels.size() > 1)
            out += labels.mid(1).join(QLatin1Char('/'));
    } else {
        out = labels.join(QLatin1Char('/'));
    }

    return normalizedClipboardPath(out);
}

QString FileManagerBridge::absolutePathForItem(const QVariantMap& item) const
{
    QString explicitPath = item.value(QStringLiteral("fullPath")).toString();
    if (explicitPath.isEmpty())
        explicitPath = item.value(QStringLiteral("path")).toString();

    if (!explicitPath.isEmpty())
        return normalizedClipboardPath(explicitPath);

    const QString base = currentDirectoryPath();
    const QString name = item.value(QStringLiteral("name")).toString();

    if (base.isEmpty())
        return normalizedClipboardPath(name);

    if (name.isEmpty())
        return base;

    return normalizedClipboardPath(QDir(base).filePath(name));
}

QString FileManagerBridge::relativePathFromCurrentDirectory(const QString& absolutePath) const
{
    const QString base = currentDirectoryPath();
    if (base.isEmpty())
        return normalizedClipboardPath(absolutePath);

    return normalizedClipboardPath(QDir(base).relativeFilePath(absolutePath));
}

QString FileManagerBridge::sidebarPathForLabel(const QString& label, const QString& kind) const
{
    if (kind == QStringLiteral("drive")) {
        const QRegularExpression rx(QStringLiteral(R"(\(([A-Za-z]:)\))"));
        const QRegularExpressionMatch match = rx.match(label);
        if (match.hasMatch())
            return normalizedClipboardPath(match.captured(1) + QStringLiteral("/"));

        if (QRegularExpression(QStringLiteral(R"(^[A-Za-z]:/?$)")).match(label).hasMatch())
            return normalizedClipboardPath(label);

        return normalizedClipboardPath(label);
    }

    if (kind == QStringLiteral("quick")) {
        if (label == QStringLiteral("Home"))
            return normalizedClipboardPath(QDir::homePath());
        if (label == QStringLiteral("Desktop"))
            return normalizedClipboardPath(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation));
        if (label == QStringLiteral("Downloads"))
            return normalizedClipboardPath(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));
        if (label == QStringLiteral("Documents"))
            return normalizedClipboardPath(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation));
        if (label == QStringLiteral("Pictures"))
            return normalizedClipboardPath(QStandardPaths::writableLocation(QStandardPaths::PicturesLocation));
        if (label == QStringLiteral("Music"))
            return normalizedClipboardPath(QStandardPaths::writableLocation(QStandardPaths::MusicLocation));
        if (label == QStringLiteral("Videos"))
            return normalizedClipboardPath(QStandardPaths::writableLocation(QStandardPaths::MoviesLocation));
        if (label == QStringLiteral("Recent")) {
#if defined(Q_OS_WIN)
            return normalizedClipboardPath(QDir::homePath()
                                           + QStringLiteral("/AppData/Roaming/Microsoft/Windows/Recent"));
#else
            return normalizedClipboardPath(QDir::homePath());
#endif
        }
    }

    return normalizedClipboardPath(label);
}

QStringList FileManagerBridge::collectedPathsForAbsolutePath(const QString& absolutePath,
                                                             bool relativeToCurrentDir,
                                                             bool recursive) const
{
    QStringList out;
    if (absolutePath.isEmpty())
        return out;

    const auto toRequestedForm = [&](const QString& path) {
        return relativeToCurrentDir
                   ? relativePathFromCurrentDirectory(path)
                   : normalizedClipboardPath(path);
    };

    const QString normalizedAbsolute = normalizedClipboardPath(absolutePath);
    out.append(toRequestedForm(normalizedAbsolute));

    if (!recursive)
        return out;

    const QFileInfo info(normalizedAbsolute);
    if (!info.exists() || !info.isDir())
        return out;

    QDirIterator it(normalizedAbsolute,
                    QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System,
                    QDirIterator::Subdirectories);

    while (it.hasNext())
        out.append(toRequestedForm(normalizedClipboardPath(it.next())));

    return out;
}

void FileManagerBridge::copyTextToClipboard(const QString& text) const
{
    if (QClipboard* clipboard = QGuiApplication::clipboard())
        clipboard->setText(text);
}

QVariantMap FileManagerBridge::buildMockPreviewForItem(const QVariantMap& item) const
{
    QVariantMap preview;

    const QString name = item.value(QStringLiteral("name")).toString();
    const QString type = item.value(QStringLiteral("type")).toString();
    const QString icon = item.value(QStringLiteral("icon")).toString();
    const QString size = item.value(QStringLiteral("size")).toString();
    const QString dateModified = item.value(QStringLiteral("dateModified")).toString();
    const QString ext = name.section(QLatin1Char('.'), -1).toLower();

    QString previewType = QStringLiteral("generic");
    QString summary;
    QVariantList lines;

    const bool isFolder =
        type.compare(QStringLiteral("File folder"), Qt::CaseInsensitive) == 0;

    const bool isImage =
        type.contains(QStringLiteral("PNG"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("JPEG"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("SVG"), Qt::CaseInsensitive)
        || ext == QStringLiteral("png")
        || ext == QStringLiteral("jpg")
        || ext == QStringLiteral("jpeg")
        || ext == QStringLiteral("svg")
        || ext == QStringLiteral("bmp")
        || ext == QStringLiteral("gif")
        || ext == QStringLiteral("webp");

    const bool isDocument =
        type.contains(QStringLiteral("PDF"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Word"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Excel"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("PowerPoint"), Qt::CaseInsensitive)
        || ext == QStringLiteral("pdf")
        || ext == QStringLiteral("doc")
        || ext == QStringLiteral("docx")
        || ext == QStringLiteral("xls")
        || ext == QStringLiteral("xlsx")
        || ext == QStringLiteral("ppt")
        || ext == QStringLiteral("pptx");

    const bool isText =
        type.contains(QStringLiteral("Text"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("JSON"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("YAML"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Markdown"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("QML"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("C++"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("PowerShell"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Batch"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Log"), Qt::CaseInsensitive)
        || ext == QStringLiteral("txt")
        || ext == QStringLiteral("json")
        || ext == QStringLiteral("yaml")
        || ext == QStringLiteral("yml")
        || ext == QStringLiteral("md")
        || ext == QStringLiteral("qml")
        || ext == QStringLiteral("cpp")
        || ext == QStringLiteral("h")
        || ext == QStringLiteral("hpp")
        || ext == QStringLiteral("ps1")
        || ext == QStringLiteral("bat")
        || ext == QStringLiteral("log");

    const bool isAudio =
        type.contains(QStringLiteral("MP3"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Audio"), Qt::CaseInsensitive)
        || ext == QStringLiteral("mp3")
        || ext == QStringLiteral("wav")
        || ext == QStringLiteral("flac");

    const bool isVideo =
        type.contains(QStringLiteral("Video"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("MP4"), Qt::CaseInsensitive)
        || ext == QStringLiteral("mp4")
        || ext == QStringLiteral("mkv")
        || ext == QStringLiteral("avi")
        || ext == QStringLiteral("mov");

    const bool isArchive =
        type.contains(QStringLiteral("Archive"), Qt::CaseInsensitive)
        || type.contains(QStringLiteral("Compressed"), Qt::CaseInsensitive)
        || ext == QStringLiteral("zip")
        || ext == QStringLiteral("7z")
        || ext == QStringLiteral("rar")
        || ext == QStringLiteral("tar");

    if (isFolder) {
        previewType = QStringLiteral("folder");
        summary = QStringLiteral("Mock folder preview wired through the backend.");
        lines << QStringLiteral("Contains a mix of files and subfolders")
              << QStringLiteral("Recent activity would appear here in a real implementation")
              << QStringLiteral("Double-click still opens the folder through the existing flow");
    } else if (isImage) {
        previewType = QStringLiteral("image");
        summary = QStringLiteral("Mock image preview generated by the backend.");
        lines << QStringLiteral("Resolution: 1920 × 1080")
              << QStringLiteral("Color profile: sRGB")
              << QStringLiteral("Thumbnail rendering can be replaced with a real backend later");
    } else if (isDocument) {
        previewType = QStringLiteral("document");
        summary = QStringLiteral("Mock document preview generated by the backend.");
        lines << QStringLiteral("Page 1 preview")
              << QStringLiteral("Executive summary / heading block")
              << QStringLiteral("Body text excerpt would be shown here later");
    } else if (isText) {
        previewType = QStringLiteral("text");

        if (ext == QStringLiteral("json")) {
            summary = QStringLiteral("Mock JSON/text preview.");
            lines << QStringLiteral("{")
                  << QStringLiteral("  \"theme\": \"Dark\",")
                  << QStringLiteral("  \"previewEnabled\": true,")
                  << QStringLiteral("  \"paneWidth\": 320")
                  << QStringLiteral("}");
        } else if (ext == QStringLiteral("yaml") || ext == QStringLiteral("yml")) {
            summary = QStringLiteral("Mock YAML/text preview.");
            lines << QStringLiteral("theme: Dark")
                  << QStringLiteral("previewEnabled: true")
                  << QStringLiteral("paneWidth: 320")
                  << QStringLiteral("viewMode: Details");
        } else if (ext == QStringLiteral("qml")) {
            summary = QStringLiteral("Mock QML source preview.");
            lines << QStringLiteral("import QtQuick")
                  << QStringLiteral("Window {")
                  << QStringLiteral("    visible: true")
                  << QStringLiteral("}");
        } else if (ext == QStringLiteral("cpp") || ext == QStringLiteral("h") || ext == QStringLiteral("hpp")) {
            summary = QStringLiteral("Mock C++ source preview.");
            lines << QStringLiteral("#include <QObject>")
                  << QStringLiteral("class Example final : public QObject")
                  << QStringLiteral("{")
                  << QStringLiteral("};");
        } else {
            summary = QStringLiteral("Mock text preview generated by the backend.");
            lines << QStringLiteral("Lorem ipsum style placeholder content")
                  << QStringLiteral("Second preview line for the selected file")
                  << QStringLiteral("Real file reading can replace this later");
        }
    } else if (isAudio) {
        previewType = QStringLiteral("audio");
        summary = QStringLiteral("Mock audio preview generated by the backend.");
        lines << QStringLiteral("Duration: 03:42")
              << QStringLiteral("Bitrate: 320 kbps")
              << QStringLiteral("Waveform / album art can be added later");
    } else if (isVideo) {
        previewType = QStringLiteral("video");
        summary = QStringLiteral("Mock video preview generated by the backend.");
        lines << QStringLiteral("Duration: 01:24")
              << QStringLiteral("Resolution: 1920 × 1080")
              << QStringLiteral("Poster frame / scrubber can be added later");
    } else if (isArchive) {
        previewType = QStringLiteral("archive");
        summary = QStringLiteral("Mock archive preview generated by the backend.");
        lines << QStringLiteral("Contains 18 items")
              << QStringLiteral("Top-level folders: 3")
              << QStringLiteral("Archive listing can be made real later");
    } else {
        previewType = QStringLiteral("generic");
        summary = QStringLiteral("Mock generic preview generated by the backend.");
        lines << QStringLiteral("No specialized preview is available yet")
              << QStringLiteral("Open / properties continue to work normally");
    }

    preview.insert(QStringLiteral("visible"), true);
    preview.insert(QStringLiteral("name"), name);
    preview.insert(QStringLiteral("type"), type);
    preview.insert(QStringLiteral("icon"),
                   icon.isEmpty() ? QStringLiteral("insert-drive-file") : icon);
    preview.insert(QStringLiteral("previewType"), previewType);
    preview.insert(QStringLiteral("size"), size);
    preview.insert(QStringLiteral("dateModified"), dateModified);
    preview.insert(QStringLiteral("summary"), summary);
    preview.insert(QStringLiteral("lines"), lines);
    preview.insert(QStringLiteral("mock"), true);

    return preview;
}

QVariantMap FileManagerBridge::previewItemByRow(int row)
{
    if (row < 0) {
        m_currentFileRow = -1;
        return clearPreview();
    }

    const QVariantMap item = m_fileOpsService->fileAt(row);
    if (item.isEmpty()) {
        m_currentFileRow = -1;
        return clearPreview();
    }

    m_currentFileRow = row;

    QVariantMap out;
    out.insert(QStringLiteral("previewEnabled"), m_previewEnabled);
    out.insert(QStringLiteral("preview"), buildMockPreviewForItem(item));
    return out;
}

QVariantMap FileManagerBridge::clearPreview()
{
    m_currentFileRow = -1;

    QVariantMap preview;
    preview.insert(QStringLiteral("visible"), false);
    preview.insert(QStringLiteral("name"), QString());
    preview.insert(QStringLiteral("type"), QString());
    preview.insert(QStringLiteral("icon"), QStringLiteral("insert-drive-file"));
    preview.insert(QStringLiteral("previewType"), QStringLiteral("none"));
    preview.insert(QStringLiteral("size"), QString());
    preview.insert(QStringLiteral("dateModified"), QString());
    preview.insert(QStringLiteral("summary"), QString());
    preview.insert(QStringLiteral("lines"), QVariantList{});

    QVariantMap out;
    out.insert(QStringLiteral("previewEnabled"), m_previewEnabled);
    out.insert(QStringLiteral("preview"), preview);
    return out;
}

QVariantMap FileManagerBridge::openSidebarLocationInNewTab(const QString& label,
                                                           const QString& icon,
                                                           const QString& kind)
{
    Q_UNUSED(icon);

    const QString tabTitle = label.trimmed().isEmpty()
                                 ? QStringLiteral("New Tab")
                                 : label.trimmed();

    m_sessionService->addTab(tabTitle);
    m_navigationService->openSidebarLocation(label, kind);
    m_fileOpsService->reloadForPath(m_navigationService->pathText());

    return makeSnapshot(QStringLiteral("[Backend] Opened %1 in a new tab").arg(tabTitle),
                        QStringLiteral("success"));
}

QVariantMap FileManagerBridge::setTheme(const QString& themeMode)
{
    m_appSettings.setTheme(themeMode);

    QVariantMap snapshot = makeSnapshot(
        QStringLiteral("[Backend] Theme set to ") + m_appSettings.theme(),
        QStringLiteral("info"));

    snapshot.insert(QStringLiteral("theme"), m_appSettings.theme());
    return snapshot;
}

QVariantMap FileManagerBridge::setPreviewEnabled(bool enabled)
{
    m_previewEnabled = enabled;
    m_appSettings.setPreviewEnabled(enabled);

    QVariantMap snapshot = makeSnapshot(
        m_previewEnabled
            ? QStringLiteral("[Backend] Preview enabled")
            : QStringLiteral("[Backend] Preview disabled"),
        QStringLiteral("info"));

    snapshot.insert(QStringLiteral("previewEnabled"), m_previewEnabled);

    if (!m_previewEnabled) {
        QVariantMap preview;
        preview.insert(QStringLiteral("visible"), false);
        preview.insert(QStringLiteral("name"), QString());
        preview.insert(QStringLiteral("type"), QString());
        preview.insert(QStringLiteral("icon"), QStringLiteral("insert-drive-file"));
        preview.insert(QStringLiteral("previewType"), QStringLiteral("none"));
        preview.insert(QStringLiteral("size"), QString());
        preview.insert(QStringLiteral("dateModified"), QString());
        preview.insert(QStringLiteral("summary"), QString());
        preview.insert(QStringLiteral("lines"), QVariantList{});
        snapshot.insert(QStringLiteral("preview"), preview);
        return snapshot;
    }

    if (m_currentFileRow >= 0) {
        const QVariantMap previewSnapshot = previewItemByRow(m_currentFileRow);
        if (previewSnapshot.contains(QStringLiteral("preview"))) {
            snapshot.insert(QStringLiteral("preview"),
                            previewSnapshot.value(QStringLiteral("preview")));
        }
    } else {
        const QVariantMap clearSnapshot = clearPreview();
        if (clearSnapshot.contains(QStringLiteral("preview"))) {
            snapshot.insert(QStringLiteral("preview"),
                            clearSnapshot.value(QStringLiteral("preview")));
        }
    }

    return snapshot;
}

QVariantMap FileManagerBridge::setShowHiddenFiles(bool enabled)
{
    m_showHiddenFiles = enabled;
    m_appSettings.setShowHiddenFiles(enabled);

    m_fileOpsService->reloadForPath(m_navigationService->pathText());

    QVariantMap snapshot = makeSnapshot(
        m_showHiddenFiles
            ? QStringLiteral("[Backend] Hidden files are now visible")
            : QStringLiteral("[Backend] Hidden files are now hidden"),
        QStringLiteral("info"));

    snapshot.insert(QStringLiteral("showHiddenFiles"), m_showHiddenFiles);
    return snapshot;
}

QString FileManagerBridge::savedTheme() const
{
    return m_appSettings.theme();
}

QString FileManagerBridge::savedSearchScope() const
{
    return m_appSettings.searchScope();
}

QString FileManagerBridge::savedViewMode() const
{
    return m_appSettings.viewMode();
}

bool FileManagerBridge::savedPreviewEnabled() const
{
    return m_appSettings.previewEnabled();
}

bool FileManagerBridge::savedShowHiddenFiles() const
{
    return m_appSettings.showHiddenFiles();
}