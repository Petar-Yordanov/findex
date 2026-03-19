#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class FileManagerSessionService;
class FileManagerNavigationService;
class FileManagerFileOpsService;
class FileManagerSearchService;
class FileManagerSidebarService;

class FileManagerBridge final : public QObject
{
    Q_OBJECT

public:
    explicit FileManagerBridge(QObject* parent = nullptr);
    ~FileManagerBridge() override;

    Q_INVOKABLE QVariantMap bootstrap();
    Q_INVOKABLE QVariantMap activateTab(int index);
    Q_INVOKABLE QVariantMap addTab(const QString& title);
    Q_INVOKABLE QVariantMap duplicateTab(int index);
    Q_INVOKABLE QVariantMap closeTab(int index);
    Q_INVOKABLE QVariantMap renameTab(int index, const QString& title);
    Q_INVOKABLE QVariantMap moveTab(int from, int to);
    Q_INVOKABLE QVariantMap navigateToPathString(const QString& pathText);
    Q_INVOKABLE QVariantMap navigateToPathParts(const QVariantList& parts);
    Q_INVOKABLE QVariantMap openSidebarLocation(const QString& label,
                                                const QString& icon,
                                                const QString& kind);
    Q_INVOKABLE QVariantMap goBack();
    Q_INVOKABLE QVariantMap goForward();
    Q_INVOKABLE QVariantMap goUp();
    Q_INVOKABLE QVariantMap refresh();
    Q_INVOKABLE QVariantMap openItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap openItemsInNewTab(const QVariantList& items);
    Q_INVOKABLE QVariantMap createFile();
    Q_INVOKABLE QVariantMap createFolder();
    Q_INVOKABLE QVariantMap renameItems(const QVariantList& items, const QString& newName);
    Q_INVOKABLE QVariantMap deleteItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap moveItems(const QVariantList& items,
                                      const QString& targetLabel,
                                      const QString& targetKind);

    Q_INVOKABLE QVariantMap copyItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap cutItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap pasteItems();
    Q_INVOKABLE QVariantMap pasteItems(const QString& targetLabel,
                                       const QString& targetKind);
    Q_INVOKABLE QVariantMap duplicateItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap compressItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap extractItems(const QVariantList& items);
    Q_INVOKABLE QVariantMap openItemByRow(int row);
    Q_INVOKABLE QVariantMap openItemInNewTabByRow(int row);
    Q_INVOKABLE QVariantMap createFileAndBeginRename();
    Q_INVOKABLE QVariantMap createFolderAndBeginRename();
    Q_INVOKABLE QVariantMap cutSelection(const QVariantList& items);
    Q_INVOKABLE QVariantMap copySelection(const QVariantList& items);
    Q_INVOKABLE QVariantMap deleteSelection(const QVariantList& items);
    Q_INVOKABLE QVariantMap showProperties(const QVariantList& items);
    Q_INVOKABLE QVariantMap showItemProperties(const QVariantList& items);
    Q_INVOKABLE QVariantMap showCurrentLocationProperties();
    Q_INVOKABLE QVariantMap openItemsWith(const QVariantList& items, const QString& appName);
    Q_INVOKABLE QVariantMap chooseOpenWithApp(const QVariantList& items);
    Q_INVOKABLE QVariantMap copyItemPaths(const QVariantList& items);
    Q_INVOKABLE QVariantMap openItemsInTerminal(const QVariantList& items);
    Q_INVOKABLE QVariantMap search(const QString& query, const QString& scope);
    Q_INVOKABLE QVariantMap setSearchScope(const QString& scope);
    Q_INVOKABLE QVariantMap setTheme(const QString& themeMode);
    Q_INVOKABLE QVariantMap setViewMode(const QString& viewMode);
    Q_INVOKABLE QVariantMap openFolderByRow(int row);
    Q_INVOKABLE QVariantMap renameRow(int row, const QString& newName);
    Q_INVOKABLE QVariantMap deleteRow(int row);
    Q_INVOKABLE QVariantMap deleteRows(const QVariantList& rows);
    Q_INVOKABLE QVariantMap moveRows(const QVariantList& rows,
                                     const QString& targetLabel,
                                     const QString& targetKind);
    Q_INVOKABLE QVariantMap validateFileName(const QString& name) const;
    Q_INVOKABLE QVariantMap commitPathText(const QString& pathText);
    Q_INVOKABLE QVariantMap commitSearchText(const QString& query, const QString& scope);
    Q_INVOKABLE QString currentPlatform() const;
    Q_INVOKABLE QString invalidNameCharacters() const;
    Q_INVOKABLE bool isValidFileOrFolderName(const QString& name) const;
    Q_INVOKABLE QString sanitizeFileOrFolderName(const QString& name) const;
    Q_INVOKABLE QVariantMap previewItemByRow(int row);
    Q_INVOKABLE QVariantMap clearPreview();

private:
    QVariantMap makeSnapshot(const QString& message = QString(),
                             const QString& messageKind = QString()) const;
    QVariantList normalizeItems(const QVariantList& items) const;
    QVariantList rowsFromItems(const QVariantList& items) const;
    QVariantList singleRowItemList(int row) const;
    QString describeItemCount(const QVariantList& items) const;
    bool isValidFileName(const QString& name, QString* error = nullptr) const;
    bool isValidPathText(const QString& pathText, QString* error = nullptr) const;
    QVariantMap buildMockPreviewForItem(const QVariantMap& item) const;

private:
    FileManagerSessionService* m_sessionService;
    FileManagerNavigationService* m_navigationService;
    FileManagerFileOpsService* m_fileOpsService;
    FileManagerSearchService* m_searchService;
    FileManagerSidebarService* m_sidebarService;
};