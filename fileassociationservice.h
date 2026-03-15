#pragma once

#include <QList>
#include <QString>
#include <QUrl>

class FileAssociationService
{
public:
    struct AssociatedApp
    {
        QString id;
        QString name;
        QString executable;
        QString command;
        QUrl appUrl;
        bool isDefault = false;
    };

    static QList<AssociatedApp> appsForFile(const QString& filePath);
    static QList<AssociatedApp> appsForExtension(const QString& extension);
    static QList<AssociatedApp> appsForMimeType(const QString& mimeType);

private:
    static QString normalizeExtension(QString extension);

    static QList<AssociatedApp> appsForMimeTypeImpl(const QString& mimeType,
                                                    const QString& extensionHint);
};