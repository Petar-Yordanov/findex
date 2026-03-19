#pragma once

#include <QObject>

class FileManagerSearchService final : public QObject
{
    Q_OBJECT

public:
    explicit FileManagerSearchService(QObject* parent = nullptr);

    void search(const QString& query, const QString& scope);
};