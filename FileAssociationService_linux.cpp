#include <QtSystemDetection>

#ifdef Q_OS_LINUX

#include "FileAssociationService.h"
#include <gio/gio.h>
#include <QHash>
#include <QList>

namespace
{
void addUnique(QList<FileAssociationService::AssociatedApp>& apps,
               QHash<QString, int>& seen,
               const FileAssociationService::AssociatedApp& app)
{
    const QString key =
        !app.id.isEmpty() ? app.id.toLower()
        : !app.executable.isEmpty() ? app.executable.toLower()
                                    : app.name.toLower();

    if (key.isEmpty()) {
        return;
    }

    if (seen.contains(key)) {
        auto& existing = apps[seen[key]];
        existing.isDefault = existing.isDefault || app.isDefault;
        if (existing.name.isEmpty()) existing.name = app.name;
        if (existing.command.isEmpty()) existing.command = app.command;
        if (existing.executable.isEmpty()) existing.executable = app.executable;
        return;
    }

    seen.insert(key, apps.size());
    apps.push_back(app);
}

QString fromUtf8(const char* s)
{
    return s ? QString::fromUtf8(s) : QString();
}
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForMimeTypeImpl(const QString& mimeType, const QString& extensionHint)
{
    Q_UNUSED(extensionHint);

    QList<AssociatedApp> apps;
    QHash<QString, int> seen;

    if (mimeType.isEmpty()) {
        return apps;
    }

    const QByteArray mimeUtf8 = mimeType.toUtf8();

    GAppInfo* defaultApp = g_app_info_get_default_for_type(mimeUtf8.constData(), FALSE);
    QString defaultId;
    if (defaultApp) {
        const char* id = g_app_info_get_id(defaultApp);
        defaultId = fromUtf8(id);
    }

    GList* list = g_app_info_get_all_for_type(mimeUtf8.constData());
    for (GList* it = list; it != nullptr; it = it->next) {
        GAppInfo* info = G_APP_INFO(it->data);
        if (!info) {
            continue;
        }

        AssociatedApp app;
        app.id = fromUtf8(g_app_info_get_id(info));
        app.name = fromUtf8(g_app_info_get_display_name(info));
        if (app.name.isEmpty()) {
            app.name = fromUtf8(g_app_info_get_name(info));
        }
        app.executable = fromUtf8(g_app_info_get_executable(info));
        app.command = fromUtf8(g_app_info_get_commandline(info));
        app.isDefault = (!defaultId.isEmpty() && app.id == defaultId);

        addUnique(apps, seen, app);
        g_object_unref(info);
    }

    g_list_free(list);

    if (defaultApp) {
        g_object_unref(defaultApp);
    }

    return apps;
}

#endif
