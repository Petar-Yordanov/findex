#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

class FileListModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    struct FileItem
    {
        QString name;
        QString dateModified;
        QString type;
        QString size;
        QString icon;
        bool isDir = false;
    };

    enum Roles
    {
        NameRole = Qt::UserRole + 1,
        DateModifiedRole,
        TypeRole,
        SizeRole,
        IconRole,
        IsDirRole
    };
    Q_ENUM(Roles)

    explicit FileListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setItems(const QVector<FileItem>& items);
    QVector<FileItem> items() const;

    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void loadDefaults();

private:
    QVector<FileItem> m_items;
};