#include "FileManagerSearchService.h"

FileManagerSearchService::FileManagerSearchService(QObject* parent)
    : QObject(parent)
{
}

void FileManagerSearchService::search(const QString& query, const QString& scope)
{
    Q_UNUSED(query);
    Q_UNUSED(scope);
}