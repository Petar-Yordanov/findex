#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

class QuickAccessModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    struct QuickAccessItem
    {
        QString label;
        QString path;
        QString icon;
        QString kind;

        bool operator==(const QuickAccessItem& other) const
        {
            return label == other.label
                   && path == other.path
                   && icon == other.icon
                   && kind == other.kind;
        }
    };

    enum Roles
    {
        LabelRole = Qt::UserRole + 1,
        PathRole,
        IconRole,
        KindRole
    };
    Q_ENUM(Roles)

    explicit QuickAccessModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void loadDefaults();

private:
    QVector<QuickAccessItem> m_items;
};
