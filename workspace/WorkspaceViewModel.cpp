#include "workspace/WorkspaceViewModel.h"

#include <QVariantList>
#include <algorithm>

#include <Qt>

WorkspaceViewModel::WorkspaceViewModel(QObject* parent)
    : QObject(parent)
    , m_fileModel(this)
    , m_viewMode(normalizeViewMode(m_settings.viewMode()))
{
    m_fileModel.loadDefaults(m_currentDirectoryPath);

    if (m_fileModel.rowCount() > 0)
    {
        m_currentIndex = 0;
        m_selectionAnchorRow = 0;
        m_selectedRows.insert(0);
    }
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
    if (selectedItems() > 0)
    {
        return QString::number(totalItems())
        + QStringLiteral(" items ")
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
    QString normalized = value.trimmed();
    if (normalized.isEmpty())
        normalized = QStringLiteral("C:/Projects/Findex");

    normalized.replace('\\', '/');
    while (normalized.contains(QStringLiteral("//")))
        normalized.replace(QStringLiteral("//"), QStringLiteral("/"));

    if (m_currentDirectoryPath == normalized)
        return;

    m_currentDirectoryPath = normalized;
    emit currentDirectoryPathChanged();
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

void WorkspaceViewModel::setViewMode(const QString& value)
{
    const QString resolved = normalizeViewMode(value);
    if (m_viewMode == resolved)
        return;

    m_viewMode = resolved;
    m_settings.setViewMode(m_viewMode);
    emit viewModeChanged();
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

    selectOnlyRow(row);

    const QVariantMap item = fileAt(row);
    if (item.value(QStringLiteral("isDir")).toBool())
    {
        setCurrentDirectoryPath(item.value(QStringLiteral("path")).toString());
        emit openDirectoryRequested(item);
    }
    else
    {
        emit openFileRequested(item);
    }
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

    if (m_draggingItems)
        return;

    m_draggingItems = true;
    emit draggingItemsChanged();
}

void WorkspaceViewModel::finishFileDrag(bool accepted)
{
    if (!m_draggingItems)
        return;

    Q_UNUSED(accepted);
    clearDragState();
}

void WorkspaceViewModel::cancelFileDrag()
{
    if (!m_draggingItems)
        return;

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

    emit fileDropRequested(
        m_draggedItems,
        targetPath,
        targetKind.trimmed().isEmpty() ? QStringLiteral("path") : targetKind);
}

bool WorkspaceViewModel::isOnlyDraggingRow(int row) const
{
    if (!m_draggingItems || m_draggedItems.size() != 1 || !isValidRow(row))
        return false;

    const QString rowPath = fileAt(row).value(QStringLiteral("path")).toString();
    const QString draggedPath = m_draggedItems.first().toMap().value(QStringLiteral("path")).toString();

    return rowPath.compare(draggedPath, Qt::CaseInsensitive) == 0;
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

    if (wasDragging)
        emit draggingItemsChanged();
}