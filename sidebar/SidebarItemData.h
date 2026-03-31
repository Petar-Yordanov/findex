#pragma once

#include <QString>

struct SidebarItemData
{
    QString label;
    QString icon;
    QString kind;
    QString path;
    bool section = false;
    bool expandedByDefault = false;
};