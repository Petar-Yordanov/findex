#pragma once

#include <QObject>
#include <QVariantList>

class FileManagerSidebarService final : public QObject
{
    Q_OBJECT

public:
    explicit FileManagerSidebarService(QObject* parent = nullptr);

    QVariantList drives() const;
    QVariantList sidebarTree() const;

private:
    QVariantList m_drives;
    QVariantList m_sidebarTree;
};