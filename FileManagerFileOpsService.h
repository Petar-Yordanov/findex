#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class FileManagerFileOpsService final : public QObject
{
    Q_OBJECT

public:
    explicit FileManagerFileOpsService(QObject* parent = nullptr);

    QVariantList files() const;
    QVariantMap fileAt(int row) const;

    void reloadForPath(const QString& pathText);

    void createFile();
    void createFolder();
    void renameRow(int row, const QString& newName);
    void deleteRow(int row);
    void deleteRows(const QVariantList& rows);
    void moveRows(const QVariantList& rows, const QString& targetLabel, const QString& targetKind);

private:
    QVariantMap makeFile(const QString& name,
                         const QString& dateModified,
                         const QString& type,
                         const QString& size,
                         const QString& icon) const;

private:
    QVariantList m_files;
};