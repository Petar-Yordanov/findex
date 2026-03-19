#pragma once

#include <QObject>
#include <QVariantList>
#include <QStringList>

class FileManagerNavigationService final : public QObject
{
    Q_OBJECT

public:
    explicit FileManagerNavigationService(QObject* parent = nullptr);

    QVariantList pathParts() const;
    QString pathText() const;

    void navigateToPathString(const QString& pathText);
    void navigateToPathParts(const QVariantList& parts);
    void openSidebarLocation(const QString& label, const QString& kind);
    void appendPathSegment(const QString& segment);
    void goBack();
    void goForward();
    void goUp();

private:
    QVariantMap makePathPart(const QString& label, const QString& icon) const;
    QStringList parsePath(const QString& pathText) const;
    QString toPathText(const QStringList& parts) const;
    void pushHistory(const QString& pathText);

private:
    QStringList m_pathParts;
    QStringList m_history;
    int m_historyIndex = -1;
};