#pragma once

#include <QObject>
#include <QString>

#include "navigation/NavigationBreadcrumbModel.h"

class NavigationViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QObject* backend READ backend WRITE setBackend NOTIFY backendChanged)
    Q_PROPERTY(QAbstractItemModel* breadcrumbModel READ breadcrumbModel CONSTANT)
    Q_PROPERTY(bool editingPath READ editingPath WRITE setEditingPath NOTIFY editingPathChanged)
    Q_PROPERTY(QString pathText READ pathText NOTIFY pathTextChanged)
    Q_PROPERTY(QString currentSearch READ currentSearch WRITE setCurrentSearch NOTIFY currentSearchChanged)
    Q_PROPERTY(QString searchScope READ searchScope WRITE setSearchScope NOTIFY searchScopeChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY navigationStateChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY navigationStateChanged)
    Q_PROPERTY(bool canGoUp READ canGoUp NOTIFY navigationStateChanged)

public:
    explicit NavigationViewModel(QObject* parent = nullptr);

    QObject* backend() const;
    void setBackend(QObject* backend);

    QAbstractItemModel* breadcrumbModel();

    bool editingPath() const;
    void setEditingPath(bool value);

    QString pathText() const;

    QString currentSearch() const;
    void setCurrentSearch(const QString& value);

    QString searchScope() const;
    void setSearchScope(const QString& value);

    bool canGoBack() const;
    bool canGoForward() const;
    bool canGoUp() const;

    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();
    Q_INVOKABLE void goUp();
    Q_INVOKABLE void refresh();

    Q_INVOKABLE void beginPathEdit();
    Q_INVOKABLE void cancelPathEdit();
    Q_INVOKABLE void commitPathEdit(const QString& text);
    Q_INVOKABLE void navigateToBreadcrumb(int index);

    Q_INVOKABLE void submitSearch();

signals:
    void backendChanged();
    void editingPathChanged();
    void pathTextChanged();
    void currentSearchChanged();
    void searchScopeChanged();
    void navigationStateChanged();

private:
    void setBreadcrumbsFromPathText(const QString& text);
    void seedDefaultBreadcrumbsIfEmpty();
    QString normalizedPathText(const QString& text) const;
    void syncPathTextFromBreadcrumbs();
    void invokeBackendNoArgs(const char* methodName);
    void invokeBackendOneStringArg(const char* methodName, const QString& value);
    void invokeBackendSearch();

private:
    QObject* m_backend = nullptr;
    NavigationBreadcrumbModel m_breadcrumbModel;
    bool m_editingPath = false;
    QString m_pathText;
    QString m_currentSearch;
    QString m_searchScope = QStringLiteral("folder");
};