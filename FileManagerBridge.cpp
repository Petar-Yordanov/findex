#include "FileManagerBridge.h"

#include "FileManagerSessionService.h"
#include "FileManagerNavigationService.h"
#include "FileManagerFileOpsService.h"
#include "FileManagerSearchService.h"
#include "FileManagerSidebarService.h"

#include <QStringList>

FileManagerBridge::FileManagerBridge(QObject* parent)
    : QObject(parent)
    , m_sessionService(new FileManagerSessionService(this))
    , m_navigationService(new FileManagerNavigationService(this))
    , m_fileOpsService(new FileManagerFileOpsService(this))
    , m_searchService(new FileManagerSearchService(this))
    , m_sidebarService(new FileManagerSidebarService(this))
{
}

FileManagerBridge::~FileManagerBridge() = default;

QVariantMap FileManagerBridge::makeSnapshot(const QString& message,
                                            const QString& messageKind) const
{
    QVariantMap out;
    out.insert("currentTab", m_sessionService->currentTabIndex());
    out.insert("tabs", m_sessionService->tabs());
    out.insert("path", m_navigationService->pathParts());
    out.insert("pathText", m_navigationService->pathText());
    out.insert("files", m_fileOpsService->files());
    out.insert("drives", m_sidebarService->drives());
    out.insert("sidebar", m_sidebarService->sidebarTree());
    out.insert("message", message);
    out.insert("messageKind", messageKind.isEmpty() ? QStringLiteral("info") : messageKind);
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
    m_sessionService->renameTab(index, title);
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
        return makeSnapshot(QStringLiteral("[Backend] No items to open in new tab"), QStringLiteral("info"));

    const int row = rows.first().toInt();
    const QVariantMap item = m_fileOpsService->fileAt(row);
    const QString title = item.value(QStringLiteral("name")).toString().isEmpty()
                              ? QStringLiteral("New Tab")
                              : item.value(QStringLiteral("name")).toString();

    m_sessionService->addTab(title);
    return makeSnapshot(QStringLiteral("[Backend] Opened item in new tab"), QStringLiteral("success"));
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

    m_fileOpsService->renameRow(rows.first().toInt(), newName);
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

QVariantMap FileManagerBridge::copyItemPaths(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No item paths to copy"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Copied path for ") + describeItemCount(items),
                        QStringLiteral("success"));
}

QVariantMap FileManagerBridge::openItemsInTerminal(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] No item location to open in terminal"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Opened terminal for ") + describeItemCount(items),
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::search(const QString& query, const QString& scope)
{
    m_searchService->search(query, scope);
    return makeSnapshot(QStringLiteral("[Backend] Search complete"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::setSearchScope(const QString& scope)
{
    return makeSnapshot(QStringLiteral("[Backend] Search scope set to ") + scope, QStringLiteral("info"));
}

QVariantMap FileManagerBridge::setTheme(const QString& themeMode)
{
    return makeSnapshot(QStringLiteral("[Backend] Theme set to ") + themeMode, QStringLiteral("info"));
}

QVariantMap FileManagerBridge::setViewMode(const QString& viewMode)
{
    return makeSnapshot(QStringLiteral("[Backend] View mode set to ") + viewMode, QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openNotifications()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened notifications"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openCreateMenu()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened create menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openMoreActionsMenu()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened more actions menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openViewModeMenu()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened view mode menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openThemeMenu()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened theme menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openSearchScopeMenu()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened search scope menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openTabContextMenu(int index)
{
    Q_UNUSED(index);
    return makeSnapshot(QStringLiteral("[Backend] Opened tab context menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openSidebarContextMenu(const QString& label,
                                                      const QString& kind)
{
    Q_UNUSED(label);
    Q_UNUSED(kind);
    return makeSnapshot(QStringLiteral("[Backend] Opened sidebar context menu"), QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openItemContextMenu(const QVariantList& items)
{
    if (normalizeItems(items).isEmpty())
        return makeSnapshot(QStringLiteral("[Backend] Opened empty item context menu"), QStringLiteral("info"));

    return makeSnapshot(QStringLiteral("[Backend] Opened item context menu for ") + describeItemCount(items),
                        QStringLiteral("info"));
}

QVariantMap FileManagerBridge::openEmptyAreaContextMenu()
{
    return makeSnapshot(QStringLiteral("[Backend] Opened empty area context menu"), QStringLiteral("info"));
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