#pragma once

#include <QObject>
#include <QString>

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

    Q_INVOKABLE void addTab();
    Q_INVOKABLE void closeTab(int index);
    Q_INVOKABLE void activateTab(int index);
    Q_INVOKABLE void beginRenameTab(int index);
    Q_INVOKABLE void commitRenameTab(int index, const QString& title);
    Q_INVOKABLE void cancelRenameTab();
    Q_INVOKABLE void moveTab(int from, int to);

signals:
    void currentIndexChanged();
    void editingIndexChanged();
    void editingTitleChanged();

private:
    void setCurrentIndexInternal(int index);
    void setEditingIndexInternal(int index);

private:
    TabListModel m_tabsModel;
    int m_currentIndex = 0;
    int m_editingIndex = -1;
    QString m_editingTitle;
};