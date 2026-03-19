#include "FileManagerSidebarService.h"

FileManagerSidebarService::FileManagerSidebarService(QObject* parent)
    : QObject(parent)
{
    m_drives = {
        QVariantMap{{"label","Local Disk (C:)"},{"icon","hard-drive"},{"used",0.5},{"total",1.0},{"usedText","0.5 TB used of 1 TB"}},
        QVariantMap{{"label","Data (D:)"},{"icon","storage"},{"used",0.37},{"total",1.0},{"usedText","0.37 TB used of 1 TB"}},
        QVariantMap{{"label","Backup (E:)"},{"icon","save"},{"used",0.91},{"total",1.0},{"usedText","0.91 TB used of 1 TB"}},
        QVariantMap{{"label","USB Drive (F:)"},{"icon","usb"},{"used",0.18},{"total",1.0},{"usedText","0.18 TB used of 1 TB"}}
    };

    m_sidebarTree = {
        QVariantMap{
            {"label","Quick Access"},
            {"icon",""},
            {"section",true},
            {"kind","section"},
            {"rows", QVariantList{
                         QVariantMap{{"label","Recent"},{"icon","history"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Home"},{"icon","home"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Desktop"},{"icon","desktop-windows"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Downloads"},{"icon","download"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Documents"},{"icon","description"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Pictures"},{"icon","image"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Music"},{"icon","music-note"},{"kind","quick"},{"section",false}},
                         QVariantMap{{"label","Videos"},{"icon","movie"},{"kind","quick"},{"section",false}}
                     }}
        }
    };
}

QVariantList FileManagerSidebarService::drives() const
{
    return m_drives;
}

QVariantList FileManagerSidebarService::sidebarTree() const
{
    return m_sidebarTree;
}