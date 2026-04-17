#pragma once

#include <QObject>
#include <QSet>
#include <QString>
#include <QStringList>
#include <QThread>
#include <QVariantList>

#include "ApplicationSettings.h"
#include "workspace/FileListModel.h"

class FileOperationWorker;

class WorkspaceViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(FileListModel* fileModel READ fileModel CONSTANT)
    Q_PROPERTY(QString viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(QString viewModeIcon READ viewModeIcon NOTIFY viewModeChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(int selectedItems READ selectedItems NOTIFY selectedItemsChanged)
    Q_PROPERTY(QString itemsText READ itemsText NOTIFY itemsTextChanged)
    Q_PROPERTY(bool dragSelecting READ dragSelecting NOTIFY dragSelectingChanged)
    Q_PROPERTY(int selectionRevision READ selectionRevision NOTIFY selectionStateChanged)
    Q_PROPERTY(QString sortField READ sortField NOTIFY sortChanged)
    Q_PROPERTY(bool sortDescending READ sortDescending NOTIFY sortChanged)

    Q_PROPERTY(QString currentDirectoryPath READ currentDirectoryPath WRITE setCurrentDirectoryPath NOTIFY currentDirectoryPathChanged)
    Q_PROPERTY(bool draggingItems READ draggingItems NOTIFY draggingItemsChanged)
    Q_PROPERTY(QVariantList draggedItems READ draggedItems NOTIFY draggingItemsChanged)
    Q_PROPERTY(QString draggedPathsText READ draggedPathsText NOTIFY draggingItemsChanged)

    Q_PROPERTY(bool dragPreviewVisible READ dragPreviewVisible NOTIFY dragPreviewChanged)
    Q_PROPERTY(qreal dragPreviewX READ dragPreviewX NOTIFY dragPreviewChanged)
    Q_PROPERTY(qreal dragPreviewY READ dragPreviewY NOTIFY dragPreviewChanged)
    Q_PROPERTY(QString dragPreviewText READ dragPreviewText NOTIFY dragPreviewChanged)
    Q_PROPERTY(QString dragPreviewIcon READ dragPreviewIcon NOTIFY dragPreviewChanged)

    Q_PROPERTY(int inlineEditRow READ inlineEditRow NOTIFY inlineEditStateChanged)
    Q_PROPERTY(QString inlineEditText READ inlineEditText NOTIFY inlineEditTextChanged)
    Q_PROPERTY(QString inlineEditError READ inlineEditError NOTIFY inlineEditErrorChanged)
    Q_PROPERTY(bool inlineEditIsNew READ inlineEditIsNew NOTIFY inlineEditStateChanged)
    Q_PROPERTY(int inlineEditFocusToken READ inlineEditFocusToken NOTIFY inlineEditFocusTokenChanged)

    Q_PROPERTY(QVariantList openWithApps READ openWithApps NOTIFY openWithAppsChanged)

public:
    explicit WorkspaceViewModel(QObject* parent = nullptr);

    FileListModel* fileModel();
    QString viewMode() const;
    QString viewModeIcon() const;
    int currentIndex() const;
    int totalItems() const;
    int selectedItems() const;
    QString itemsText() const;
    bool dragSelecting() const;
    int selectionRevision() const;
    QString sortField() const;
    bool sortDescending() const;

    QString currentDirectoryPath() const;
    void setCurrentDirectoryPath(const QString& value);

    bool draggingItems() const;
    QVariantList draggedItems() const;
    QString draggedPathsText() const;

    bool dragPreviewVisible() const;
    qreal dragPreviewX() const;
    qreal dragPreviewY() const;
    QString dragPreviewText() const;
    QString dragPreviewIcon() const;

    int inlineEditRow() const;
    QString inlineEditText() const;
    QString inlineEditError() const;
    bool inlineEditIsNew() const;
    int inlineEditFocusToken() const;

    QVariantList openWithApps() const;

    Q_INVOKABLE void setViewMode(const QString& value);

    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();
    Q_INVOKABLE void goUp();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void navigateToPathString(const QString& path);
    Q_INVOKABLE void search(const QString& query, const QString& scope);
    Q_INVOKABLE void setShowHiddenFiles(bool value);

    Q_INVOKABLE QString savedViewMode() const;
    Q_INVOKABLE bool savedShowHiddenFiles() const;
    Q_INVOKABLE void setSort(const QString& field, bool descending);
    Q_INVOKABLE void toggleSort(const QString& field);

    Q_INVOKABLE void activateRow(int row);
    Q_INVOKABLE void selectOnlyRow(int row);
    Q_INVOKABLE void toggleRowSelection(int row);
    Q_INVOKABLE void selectRange(int startRow, int endRow);
    Q_INVOKABLE void clickRow(int row, int modifiers);
    Q_INVOKABLE void openRow(int row);
    Q_INVOKABLE bool isRowSelected(int row) const;
    Q_INVOKABLE QVariantMap fileAt(int row) const;
    Q_INVOKABLE QVariantMap previewData() const;

    Q_INVOKABLE void beginDragSelection(int anchorRow);
    Q_INVOKABLE void updateDragSelection(int targetRow);
    Q_INVOKABLE void replaceSelectionRows(const QVariantList& rows, int currentRow = -1, int anchorRow = -1);
    Q_INVOKABLE void endDragSelection();

    Q_INVOKABLE void startFileDrag(int row, int modifiers = 0);
    Q_INVOKABLE void finishFileDrag(bool accepted = false);
    Q_INVOKABLE void cancelFileDrag();
    Q_INVOKABLE bool canDropOnRow(int row) const;
    Q_INVOKABLE bool canDropToPath(const QString& targetPath) const;
    Q_INVOKABLE void dropOnRow(int row, bool copy = false);
    Q_INVOKABLE void requestDropToPath(const QString& targetPath, const QString& targetKind, bool copy = false);
    Q_INVOKABLE bool isOnlyDraggingRow(int row) const;
    void performDropOperation(const QVariantList& draggedItems, const QString& targetPath, bool copy);

    Q_INVOKABLE void beginFileDragPreview(qreal overlayX, qreal overlayY, const QString& text, const QString& icon);
    Q_INVOKABLE void updateFileDragPreview(qreal overlayX, qreal overlayY);
    Q_INVOKABLE void endFileDragPreview();

    Q_INVOKABLE void requestFileContextAction(const QString& action, int row);

    Q_INVOKABLE void createFolder();
    Q_INVOKABLE void createFile();
    Q_INVOKABLE void beginRenameRow(int row);
    Q_INVOKABLE void renameSelectedItems();
    Q_INVOKABLE void updateInlineEditText(const QString& text);
    Q_INVOKABLE bool commitInlineEdit();
    Q_INVOKABLE void cancelInlineEdit();

    Q_INVOKABLE void cutSelectedItems();
    Q_INVOKABLE void copySelectedItems();
    Q_INVOKABLE void pasteItems();
    Q_INVOKABLE void duplicateSelectedItems();
    Q_INVOKABLE void deleteSelectedItems();
    Q_INVOKABLE void compressSelectedItems();
    Q_INVOKABLE void extractSelectedItems();
    Q_INVOKABLE void showProperties();
    Q_INVOKABLE void showItemProperties();
    Q_INVOKABLE void showCurrentLocationProperties();

    Q_INVOKABLE void prepareOpenWithForRow(int row);
    Q_INVOKABLE void prepareOpenWithForSelection();
    Q_INVOKABLE bool openRowWithApp(int row, const QString& appIdOrExecutable);
    Q_INVOKABLE bool openSelectionWithApp(const QString& appIdOrExecutable);

signals:
    void viewModeChanged();
    void currentIndexChanged();
    void totalItemsChanged();
    void selectedItemsChanged();
    void itemsTextChanged();
    void selectionStateChanged();
    void dragSelectingChanged();
    void sortChanged();

    void currentDirectoryPathChanged();
    void draggingItemsChanged();
    void dragPreviewChanged();

    void inlineEditStateChanged();
    void inlineEditTextChanged();
    void inlineEditErrorChanged();
    void inlineEditFocusTokenChanged();

    void openWithAppsChanged();

    void openFileRequested(const QVariantMap& fileData);
    void openDirectoryRequested(const QVariantMap& directoryData);

    void fileDropRequested(const QVariantList& draggedItems, const QString& targetPath, const QString& targetKind, bool copy);
    void fileContextActionRequested(const QString& action, const QVariantMap& item);
    void fileDragFinished(bool accepted, const QString& targetPath, const QString& targetKind);
    void contextInfoRequested(const QString& title, const QString& details, const QString& kind);

    void operationCompleted(const QString& message);
    void operationFailed(const QString& message);
    void operationProgress(const QString& title,
                           const QString& details,
                           int progress,
                           bool done);

private:
    enum class ClipboardMode
    {
        None,
        Copy,
        Cut
    };

    QString normalizeViewMode(const QString& value) const;
    QString normalizeSortField(const QString& value) const;
    QString iconForViewMode(const QString& mode) const;
    void applySort(QVector<FileListModel::FileItem>& items) const;
    void emitSelectionSignals(int previousSelected, const QString& previousItemsText, bool selectionChanged);
    int firstSelectedRow() const;
    QVariantMap previewDataForRow(int row) const;
    QVariantList buildDraggedItems() const;
    bool isValidRow(int row) const;
    void clearDragState();
    void clearDragPreview();

    void createPendingItem(bool isDir);
    QString validateInlineEditText(const QString& text) const;
    FileListModel::FileItem buildItemFromName(const QString& name, bool isDir) const;
    void setInlineEditState(int row, const QString& text, bool isNew);
    void setInlineEditError(const QString& error);
    void clearInlineEditState();

    QString normalizePath(QString value) const;
    QString parentLocationForPath(const QString& path) const;
    QString childLocationForName(const QString& directoryPath, const QString& name) const;
    QString uniqueLocationInDirectory(const QString& directoryPath, const QString& originalName) const;
    void loadLocation(const QString& path, bool pushHistory = true);
    void reloadListing();
    QVector<FileListModel::FileItem> listDirectoryItems(const QString& path);
    QVector<FileListModel::FileItem> searchItems(const QString& basePath,
                                                 const QString& query,
                                                 const QString& scope);
    void resetSelectionToFirstItem();
    bool restoreSelectionToPaths(const QStringList& paths, const QString& currentPath);

    QVariantList selectedItemsAsMaps() const;
    QStringList selectedPaths() const;
    QString currentSelectedFilePath() const;
    void setOpenWithAppsForPath(const QString& filePath);
    void selectPathIfVisible(const QString& path);
    void copySelectedPathTextToClipboard();
    void openContainingFolderForSelection();
    void emitPropertiesForItem(const QVariantMap& item);
    QString buildPropertiesDetails(const QVariantMap& item) const;

    bool operationInProgress() const;
    void startAsyncDuplicateOperation(const QStringList& sourcePaths);
    void startAsyncTransferOperation(const QStringList& sourcePaths,
                                     const QString& destinationDirectory,
                                     bool copy,
                                     const QString& successMessageTemplate,
                                     const QString& failureMessage);
    void attachWorker(FileOperationWorker* worker, QThread* thread);

private:
    ApplicationSettings m_settings;
    FileListModel m_fileModel;
    QString m_viewMode;
    QString m_sortField;
    bool m_sortDescending = false;
    int m_currentIndex = -1;
    int m_selectionAnchorRow = -1;
    QSet<int> m_selectedRows;
    bool m_dragSelecting = false;
    int m_selectionRevision = 0;

    QString m_currentDirectoryPath;
    bool m_draggingItems = false;
    QVariantList m_draggedItems;

    bool m_dragPreviewVisible = false;
    qreal m_dragPreviewX = 0.0;
    qreal m_dragPreviewY = 0.0;
    QString m_dragPreviewText;
    QString m_dragPreviewIcon = QStringLiteral("insert-drive-file");

    QString m_lastDropTargetPath;
    QString m_lastDropTargetKind;

    int m_inlineEditRow = -1;
    QString m_inlineEditText;
    QString m_inlineEditError;
    bool m_inlineEditIsNew = false;
    int m_inlineEditFocusToken = 0;

    QStringList m_history;
    int m_historyIndex = -1;

    QString m_activeSearch;
    QString m_activeSearchScope = QStringLiteral("folder");

    ClipboardMode m_clipboardMode = ClipboardMode::None;
    QStringList m_clipboardPaths;

    QVariantList m_openWithApps;

    QThread* m_operationThread = nullptr;
};