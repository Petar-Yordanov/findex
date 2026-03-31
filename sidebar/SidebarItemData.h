#pragma once

#include <QString>

struct SidebarItemData
{
    QString label;
    QString icon;
    QString kind;
    bool section = false;
    bool expandedByDefault = false;
};