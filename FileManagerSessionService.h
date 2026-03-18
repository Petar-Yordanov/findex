#pragma once

#include <QObject>
#include <QVariantList>

class FileManagerSessionService final : public QObject
{
    Q_OBJECT

public:
    explicit FileManagerSessionService(QObject* parent = nullptr);

    int currentTabIndex() const;
    QVariantList tabs() const;

    void activateTab(int index);
    void addTab(const QString& title);
    void duplicateTab(int index);
    void closeTab(int index);
    void renameTab(int index, const QString& title);
    void moveTab(int from, int to);

private:
    int m_currentTabIndex = 0;
    QVariantList m_tabs;
};