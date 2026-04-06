#include "workspace/WorkspaceViewModel.h"

#include "FileAssociationService.h"

#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QMimeDatabase>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QVariantList>
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

QString iconForFileInfo(const QFileInfo& info)
{
    if (info.isDir())
        return QStringLiteral("folder");

    const QString suffix = info.suffix().toLower();

    if (suffix == QStringLiteral("txt") || suffix == QStringLiteral("doc") || suffix == QStringLiteral("docx"))
        return QStringLiteral("description");
    if (suffix == QStringLiteral("pdf"))
        return QStringLiteral("picture-as-pdf");
    if (suffix == QStringLiteral("png") || suffix == QStringLiteral("jpg")
        || suffix == QStringLiteral("jpeg") || suffix == QStringLiteral("svg")
        || suffix == QStringLiteral("gif") || suffix == QStringLiteral("webp"))
        return QStringLiteral("image");
    if (suffix == QStringLiteral("mp3") || suffix == QStringLiteral("wav") || suffix == QStringLiteral("flac"))
        return QStringLiteral("music-note");
    if (suffix == QStringLiteral("mp4") || suffix == QStringLiteral("mkv")
        || suffix == QStringLiteral("avi") || suffix == QStringLiteral("mov"))
        return QStringLiteral("movie");
    if (suffix == QStringLiteral("zip") || suffix == QStringLiteral("7z") || suffix == QStringLiteral("rar")
        || suffix == QStringLiteral("tar") || suffix == QStringLiteral("gz"))
        return QStringLiteral("zip");
    if (suffix == QStringLiteral("cpp") || suffix == QStringLiteral("h") || suffix == QStringLiteral("hpp")
        || suffix == QStringLiteral("c") || suffix == QStringLiteral("qml")
        || suffix == QStringLiteral("json") || suffix == QStringLiteral("yaml")
        || suffix == QStringLiteral("yml") || suffix == QStringLiteral("xml"))
        return QStringLiteral("code");
    if (suffix == QStringLiteral("ps1") || suffix == QStringLiteral("bat") || suffix == QStringLiteral("sh"))
        return QStringLiteral("terminal");

    return QStringLiteral("insert-drive-file");
}

QString typeForFileInfo(const QFileInfo& info)
{
    if (info.isDir())
        return QStringLiteral("File folder");

    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile(info);

    if (mime.isValid() && !mime.comment().trimmed().isEmpty())
        return mime.comment().trimmed();

    const QString suffix = info.suffix().toLower();
    if (!suffix.isEmpty())
        return QStringLiteral("%1 File").arg(suffix.toUpper());

    return QStringLiteral("File");
}

FileListModel::FileItem buildItemFromInfo(const QFileInfo& info)
{
    FileListModel::FileItem item;
    item.name = info.fileName();
    item.path = QDir::fromNativeSeparators(info.absoluteFilePath());
    item.dateModified = info.lastModified().toString(QStringLiteral("dd/MM/yyyy HH:mm"));
    item.type = typeForFileInfo(info);
    item.size = info.isDir() ? QString() : formatBytes(info.size());
    item.icon = iconForFileInfo(info);
    item.isDir = info.isDir();
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

bool copyRecursively(const QString& sourcePath, const QString& destPath)
{
    QFileInfo sourceInfo(sourcePath);
    if (!sourceInfo.exists())
        return false;

    if (sourceInfo.isDir()) {
        QDir destDir;
        if (!destDir.mkpath(destPath))
            return false;

        QDir srcDir(sourcePath);
        const QFileInfoList entries = srcDir.entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);

        for (const QFileInfo& entry : entries) {
            const QString nextSource = entry.absoluteFilePath();
            const QString nextDest = QDir(destPath).filePath(entry.fileName());
            if (!copyRecursively(nextSource, nextDest))
                return false;
        }

        return true;
    }

    QFile::remove(destPath);
    return QFile::copy(sourcePath, destPath);
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

bool movePathSmart(const QString& sourcePath, const QString& destPath)
{
    if (QFile::rename(sourcePath, destPath))
        return true;

    if (!copyRecursively(sourcePath, destPath))
        return false;

    return removeRecursively(sourcePath);
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
}

WorkspaceViewModel::WorkspaceViewModel(QObject* parent)
    : QObject(parent)
    , m_viewMode(normalizeViewMode(m_settings.viewMode()))
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

    for (const QVariant& entry : m_draggedItems)
    {
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
    const QFileInfo info(m_currentDirectoryPath);
    const QDir parentDir = info.dir();

    QString parentPath = QDir::fromNativeSeparators(parentDir.absolutePath());
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

    if (m_currentIndex != row)
    {
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

    if (m_selectedRows.contains(row))
    {
        if (m_selectedRows.size() > 1)
            m_selectedRows.remove(row);
    }
    else
    {
        m_selectedRows.insert(row);
    }

    m_selectionAnchorRow = row;

    if (m_currentIndex != row)
    {
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

    if (m_currentIndex != endRow)
    {
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

    if (keyboardModifiers.testFlag(Qt::ShiftModifier))
    {
        const int anchor =
            (m_selectionAnchorRow >= 0 && m_selectionAnchorRow < m_fileModel.rowCount())
                ? m_selectionAnchorRow
                : row;
        selectRange(anchor, row);
        return;
    }

    if (keyboardModifiers.testFlag(Qt::ControlModifier))
    {
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

    if (item.value(QStringLiteral("isDir")).toBool())
    {
        loadLocation(path, true);
        emit openDirectoryRequested(item);
        return;
    }

    const bool ok = FileAssociationService::openWithDefaultApp(path);
    emit openFileRequested(item);

    if (ok)
        emit operationCompleted(QStringLiteral("Opened %1").arg(item.value(QStringLiteral("name")).toString()));
    else
        emit operationFailed(QStringLiteral("Failed to open %1").arg(item.value(QStringLiteral("name")).toString()));
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

    for (int row : rows)
    {
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

    if (!m_dragSelecting)
    {
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

    for (const QVariant& value : rows)
    {
        const int row = value.toInt();
        if (row >= 0 && row < count)
            nextRows.insert(row);
    }

    if (nextRows.isEmpty())
        return;

    m_selectedRows = nextRows;

    if (anchorRow >= 0 && anchorRow < count)
        m_selectionAnchorRow = anchorRow;

    if (currentRow >= 0 && currentRow < count && m_currentIndex != currentRow)
    {
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

    const Qt::KeyboardModifiers keyboardModifiers =
        static_cast<Qt::KeyboardModifiers>(modifiers);

    if (keyboardModifiers.testFlag(Qt::ControlModifier)
        || keyboardModifiers.testFlag(Qt::ShiftModifier)
        || keyboardModifiers.testFlag(Qt::AltModifier))
    {
        return;
    }

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

    QString normalized = targetPath.trimmed();
    if (normalized.isEmpty())
        return false;

    normalized.replace('\\', '/');

    for (const QVariant& entry : m_draggedItems)
    {
        const QVariantMap item = entry.toMap();
        const QString draggedPath = item.value(QStringLiteral("path")).toString();
        if (draggedPath.compare(normalized, Qt::CaseInsensitive) == 0)
            return false;
    }

    return true;
}

void WorkspaceViewModel::dropOnRow(int row)
{
    if (!canDropOnRow(row))
        return;

    const QVariantMap item = fileAt(row);
    requestDropToPath(item.value(QStringLiteral("path")).toString(), QStringLiteral("folder"));
}

void WorkspaceViewModel::requestDropToPath(const QString& targetPath, const QString& targetKind)
{
    if (!canDropToPath(targetPath))
        return;

    m_lastDropTargetPath = targetPath;
    m_lastDropTargetKind = targetKind.trimmed().isEmpty() ? QStringLiteral("path") : targetKind;

    emit fileDropRequested(
        m_draggedItems,
        m_lastDropTargetPath,
        m_lastDropTargetKind);
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
        && qFuzzyCompare(m_dragPreviewY + 1.0, overlayY + 1.0))
    {
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

    if (trimmedAction.compare(QStringLiteral("Rename"), Qt::CaseInsensitive) == 0) {
        beginRenameRow(row);
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Copy"), Qt::CaseInsensitive) == 0) {
        selectOnlyRow(row);
        copySelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Cut"), Qt::CaseInsensitive) == 0) {
        selectOnlyRow(row);
        cutSelectedItems();
        return;
    }

    if (trimmedAction.compare(QStringLiteral("Delete"), Qt::CaseInsensitive) == 0) {
        selectOnlyRow(row);
        deleteSelectedItems();
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

    if (m_inlineEditRow >= 0 && m_inlineEditRow != row)
    {
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
        const QString newPath = QDir(m_currentDirectoryPath).filePath(trimmed);

        bool ok = false;
        if (isDir)
            ok = QDir().mkpath(newPath);
        else {
            QFile f(newPath);
            ok = f.open(QIODevice::WriteOnly);
            if (ok)
                f.close();
        }

        if (!ok) {
            setInlineEditError(QStringLiteral("Failed to create item on disk."));
            return false;
        }

        emit operationCompleted(QStringLiteral("Created %1").arg(trimmed));
    } else if (oldName.compare(trimmed, Qt::CaseInsensitive) != 0) {
        const QString newPath = QDir(m_currentDirectoryPath).filePath(trimmed);
        if (!QFile::rename(oldPath, newPath)) {
            setInlineEditError(QStringLiteral("Failed to rename item on disk."));
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

        if (m_fileModel.rowCount() > 0)
        {
            m_selectedRows.insert(0);
            m_selectionAnchorRow = 0;
            m_currentIndex = 0;
        }
        else
        {
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

    if (QGuiApplication::clipboard())
        QGuiApplication::clipboard()->setText(paths.join(QLatin1Char('\n')));

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

    if (QGuiApplication::clipboard())
        QGuiApplication::clipboard()->setText(paths.join(QLatin1Char('\n')));

    emit operationCompleted(QStringLiteral("Copied %1 item(s)").arg(paths.size()));
}

void WorkspaceViewModel::pasteItems()
{
    if (m_clipboardPaths.isEmpty() || m_clipboardMode == ClipboardMode::None) {
        emit operationFailed(QStringLiteral("Clipboard is empty."));
        return;
    }

    int successCount = 0;

    for (const QString& sourcePath : m_clipboardPaths) {
        QFileInfo srcInfo(sourcePath);
        if (!srcInfo.exists())
            continue;

        const QString destPath = uniquePathInDirectory(m_currentDirectoryPath, srcInfo.fileName());

        bool ok = false;
        if (m_clipboardMode == ClipboardMode::Copy)
            ok = copyRecursively(sourcePath, destPath);
        else
            ok = movePathSmart(sourcePath, destPath);

        if (ok)
            ++successCount;
    }

    if (m_clipboardMode == ClipboardMode::Cut) {
        m_clipboardMode = ClipboardMode::None;
        m_clipboardPaths.clear();
    }

    reloadListing();

    if (successCount > 0)
        emit operationCompleted(QStringLiteral("Pasted %1 item(s)").arg(successCount));
    else
        emit operationFailed(QStringLiteral("Paste failed."));
}

void WorkspaceViewModel::deleteSelectedItems()
{
    const QStringList paths = selectedPaths();
    if (paths.isEmpty()) {
        emit operationFailed(QStringLiteral("Nothing selected to delete."));
        return;
    }

    int deleted = 0;
    for (const QString& path : paths) {
        if (removeRecursively(path))
            ++deleted;
    }

    reloadListing();

    if (deleted > 0)
        emit operationCompleted(QStringLiteral("Deleted %1 item(s)").arg(deleted));
    else
        emit operationFailed(QStringLiteral("Delete failed."));
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

    if (selectionChanged)
    {
        ++m_selectionRevision;
        emit selectionStateChanged();
    }
}

int WorkspaceViewModel::firstSelectedRow() const
{
    if (m_selectedRows.isEmpty())
        return -1;

    int result = -1;
    for (int row : m_selectedRows)
    {
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
    const bool isDir = item.value(QStringLiteral("isDir")).toBool();

    QVariantList lines;
    lines.push_back(QStringLiteral("Name: %1").arg(name));
    lines.push_back(QStringLiteral("Path: %1").arg(item.value(QStringLiteral("path")).toString()));
    lines.push_back(QStringLiteral("Type: %1").arg(type));
    lines.push_back(QStringLiteral("Modified: %1").arg(dateModified));
    if (!size.isEmpty())
        lines.push_back(QStringLiteral("Size: %1").arg(size));

    QVariantMap data;
    data.insert(QStringLiteral("visible"), true);
    data.insert(QStringLiteral("name"), name);
    data.insert(QStringLiteral("type"), type);
    data.insert(QStringLiteral("icon"), icon.isEmpty() ? QStringLiteral("insert-drive-file") : icon);
    data.insert(QStringLiteral("previewType"), isDir ? QStringLiteral("folder") : QStringLiteral("text"));
    data.insert(QStringLiteral("size"), size);
    data.insert(QStringLiteral("dateModified"), dateModified);
    data.insert(
        QStringLiteral("summary"),
        isDir ? QStringLiteral("Folder selected.") : QStringLiteral("File selected."));
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
    for (int i = 0; i < items.size(); ++i)
    {
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

    if (isDir)
    {
        item.type = QStringLiteral("File folder");
        item.size.clear();
        item.icon = QStringLiteral("folder");
        return item;
    }

    const QString lower = item.name.toLower();

    if (lower.endsWith(QStringLiteral(".txt")))
    {
        item.type = QStringLiteral("Text Document");
        item.icon = QStringLiteral("description");
    }
    else if (lower.endsWith(QStringLiteral(".json")))
    {
        item.type = QStringLiteral("JSON Source File");
        item.icon = QStringLiteral("code");
    }
    else if (lower.endsWith(QStringLiteral(".yaml")) || lower.endsWith(QStringLiteral(".yml")))
    {
        item.type = QStringLiteral("YAML Document");
        item.icon = QStringLiteral("code");
    }
    else if (lower.endsWith(QStringLiteral(".cpp")) || lower.endsWith(QStringLiteral(".h")) || lower.endsWith(QStringLiteral(".hpp")))
    {
        item.type = QStringLiteral("C++ Source File");
        item.icon = QStringLiteral("code");
    }
    else if (lower.endsWith(QStringLiteral(".qml")))
    {
        item.type = QStringLiteral("QML File");
        item.icon = QStringLiteral("code");
    }
    else if (lower.endsWith(QStringLiteral(".png")) || lower.endsWith(QStringLiteral(".jpg")) || lower.endsWith(QStringLiteral(".jpeg")) || lower.endsWith(QStringLiteral(".svg")))
    {
        item.type = QStringLiteral("Image File");
        item.icon = QStringLiteral("image");
    }
    else if (lower.endsWith(QStringLiteral(".pdf")))
    {
        item.type = QStringLiteral("PDF Document");
        item.icon = QStringLiteral("picture-as-pdf");
    }
    else if (lower.endsWith(QStringLiteral(".zip")) || lower.endsWith(QStringLiteral(".7z")))
    {
        item.type = QStringLiteral("Archive");
        item.icon = QStringLiteral("zip");
    }
    else if (lower.endsWith(QStringLiteral(".mp3")))
    {
        item.type = QStringLiteral("MP3 File");
        item.icon = QStringLiteral("music-note");
    }
    else if (lower.endsWith(QStringLiteral(".mp4")))
    {
        item.type = QStringLiteral("MP4 Video");
        item.icon = QStringLiteral("movie");
    }
    else if (lower.endsWith(QStringLiteral(".ps1")) || lower.endsWith(QStringLiteral(".bat")))
    {
        item.type = QStringLiteral("Script File");
        item.icon = QStringLiteral("terminal");
    }
    else
    {
        item.type = QStringLiteral("File");
        item.icon = QStringLiteral("insert-drive-file");
    }

    item.size.clear();
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

    if (hadState)
    {
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
    while (value.contains(QStringLiteral("//")))
        value.replace(QStringLiteral("//"), QStringLiteral("/"));

#ifdef Q_OS_WINDOWS
    static const QRegularExpression driveOnlyRe(QStringLiteral("^([A-Za-z]:)$"));
    static const QRegularExpression driveRootRe(QStringLiteral("^([A-Za-z]:)/$"));

    QRegularExpressionMatch m = driveOnlyRe.match(value);
    if (m.hasMatch())
        return m.captured(1) + QStringLiteral("/");

    m = driveRootRe.match(value);
    if (m.hasMatch())
        return m.captured(1) + QStringLiteral("/");
#endif

    return QDir::fromNativeSeparators(QFileInfo(value).absoluteFilePath());
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
    QVector<FileListModel::FileItem> items;

    if (m_activeSearch.isEmpty())
        items = listDirectoryItems(m_currentDirectoryPath);
    else
        items = searchItems(m_currentDirectoryPath, m_activeSearch, m_activeSearchScope);

    m_fileModel.setItems(items);

    emit totalItemsChanged();
    resetSelectionToFirstItem();
}

QVector<FileListModel::FileItem> WorkspaceViewModel::listDirectoryItems(const QString& path) const
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
        QDir::DirsFirst | QDir::IgnoreCase | QDir::Name);

    result.reserve(entries.size());
    for (const QFileInfo& info : entries)
    {
        if (!shouldIncludeInfo(info, m_settings.showHiddenFiles()))
            continue;

        result.push_back(buildItemFromInfo(info));
    }

    return result;
}

QVector<FileListModel::FileItem> WorkspaceViewModel::searchItems(const QString& basePath,
                                                                 const QString& query,
                                                                 const QString& scope) const
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

            if (info.fileName().contains(trimmedQuery, Qt::CaseInsensitive))
                result.push_back(buildItemFromInfo(info));
        }
    } else {
        const QVector<FileListModel::FileItem> all = listDirectoryItems(basePath);
        for (const FileListModel::FileItem& item : all) {
            if (item.name.contains(trimmedQuery, Qt::CaseInsensitive))
                result.push_back(item);
        }
    }

    std::sort(result.begin(), result.end(), [](const auto& a, const auto& b) {
        if (a.isDir != b.isDir)
            return a.isDir && !b.isDir;
        return a.name.toLower() < b.name.toLower();
    });

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