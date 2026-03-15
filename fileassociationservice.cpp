#include "FileAssociationService.h"

#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>

QString FileAssociationService::normalizeExtension(QString extension)
{
    extension = extension.trimmed();
    if (extension.isEmpty())
        return {};

    if (!extension.startsWith('.'))
        extension.prepend('.');

    return extension.toLower();
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForFile(const QString& filePath)
{
    QFileInfo fi(filePath);
    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile(fi);

    QString ext;
    const QString suffix = fi.suffix().trimmed();
    if (!suffix.isEmpty())
        ext = "." + suffix.toLower();

    QList<AssociatedApp> apps = appsForMimeTypeImpl(mime.name(), ext);

    if (apps.isEmpty() && !ext.isEmpty())
        apps = appsForExtension(ext);

    return apps;
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForExtension(const QString& extension)
{
    const QString ext = normalizeExtension(extension);
    if (ext.isEmpty())
        return {};

    QMimeDatabase db;
    const QMimeType mime = db.mimeTypeForFile("dummy" + ext, QMimeDatabase::MatchExtension);
    return appsForMimeTypeImpl(mime.name(), ext);
}

QList<FileAssociationService::AssociatedApp>
FileAssociationService::appsForMimeType(const QString& mimeType)
{
    return appsForMimeTypeImpl(mimeType, {});
}
