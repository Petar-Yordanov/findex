#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

#include "TabListModel.h"

class TabsViewModel final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(TabListModel* tabsModel READ tabsModel CONSTANT)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int editingIndex READ editingIndex NOTIFY editingIndexChanged)
    Q_PROPERTY(QString editingTitle READ editingTitle WRITE setEditingTitle NOTIFY editingTitleChanged)

public:
    explicit TabsViewModel(QObject* parent = nullptr);

    TabListModel* tabsModel();

    int currentIndex() const;
    int editingIndex() const;
    QString editingTitle() const;

    void setEditingTitle(const QString& value);

    QVariantList saveState() const;
    void loadState(const QVariantList& tabs, int currentIndex);

    Q_INVOKABLE void addTab();
    Q_INVOKABLE void closeTab(int index);
    Q_INVOKABLE void activateTab(int index);
    Q_INVOKABLE void activateTabForDrop(int index);
    Q_INVOKABLE void beginRenameTab(int index);
    Q_INVOKABLE void commitRenameTab(int index, const QString& title);
    Q_INVOKABLE void cancelRenameTab();
    Q_INVOKABLE void moveTab(int from, int to);
    Q_INVOKABLE void setCurrentTabPath(const QString& path);

signals:
    void currentIndexChanged();
    void editingIndexChanged();
    void editingTitleChanged();
    void tabsStateChanged();

    void tabAdded(int index, const QString& title, const QString& path);
    void tabClosed(int index, const QString& title);
    void tabActivated(int index, const QString& title, const QString& path);
    void tabRenamed(int index, const QString& title);
    void tabMoved(int from, int to);

private:
    void setCurrentIndexInternal(int index);
    void setEditingIndexInternal(int index);

private:
    TabListModel m_tabsModel;
    int m_currentIndex = 0;
    int m_editingIndex = -1;
    QString m_editingTitle;
};