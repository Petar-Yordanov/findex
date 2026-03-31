#pragma once

#include "SidebarItemData.h"
#include <QVector>

struct SidebarTreeItem
{
    SidebarItemData data;
    SidebarTreeItem* parent = nullptr;
    QVector<SidebarTreeItem*> children;

    ~SidebarTreeItem()
    {
        qDeleteAll(children);
        children.clear();
    }

    int rowInParent() const
    {
        if (!parent)
            return 0;

        return parent->children.indexOf(const_cast<SidebarTreeItem*>(this));
    }
};