#pragma once

#include <QObject>
#include <QSet>
#include <QString>
#include <QVariantList>

#include "ApplicationSettings.h"
#include "workspace/FileListModel.h"

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

    Q_INVOKABLE void setViewMode(const QString& value);
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

signals:
    void viewModeChanged();
    void currentIndexChanged();
    void totalItemsChanged();
    void selectedItemsChanged();
    void itemsTextChanged();
    void selectionStateChanged();
    void dragSelectingChanged();

    void openFileRequested(const QVariantMap& fileData);
    void openDirectoryRequested(const QVariantMap& directoryData);

private:
    QString normalizeViewMode(const QString& value) const;
    QString iconForViewMode(const QString& mode) const;
    void emitSelectionSignals(int previousSelected, const QString& previousItemsText, bool selectionChanged);
    int firstSelectedRow() const;
    QVariantMap previewDataForRow(int row) const;

private:
    ApplicationSettings m_settings;
    FileListModel m_fileModel;
    QString m_viewMode;
    int m_currentIndex = -1;
    int m_selectionAnchorRow = -1;
    QSet<int> m_selectedRows;
    bool m_dragSelecting = false;
    int m_selectionRevision = 0;
};