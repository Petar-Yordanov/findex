#include "navigation/NavigationViewModel.h"

#include <QMetaObject>
#include <QVariant>
#include <QStringList>

NavigationViewModel::NavigationViewModel(QObject* parent)
    : QObject(parent)
    , m_breadcrumbModel(this)
{
    seedDefaultBreadcrumbsIfEmpty();
    syncPathTextFromBreadcrumbs();
}

QObject* NavigationViewModel::backend() const
{
    return m_backend;
}

void NavigationViewModel::setBackend(QObject* backend)
{
    if (m_backend == backend)
        return;

    m_backend = backend;
    emit backendChanged();
}

QAbstractItemModel* NavigationViewModel::breadcrumbModel()
{
    return &m_breadcrumbModel;
}

bool NavigationViewModel::editingPath() const
{
    return m_editingPath;
}

void NavigationViewModel::setEditingPath(bool value)
{
    if (m_editingPath == value)
        return;

    m_editingPath = value;
    emit editingPathChanged();
}

QString NavigationViewModel::pathText() const
{
    return m_pathText;
}

QString NavigationViewModel::currentSearch() const
{
    return m_currentSearch;
}

void NavigationViewModel::setCurrentSearch(const QString& value)
{
    if (m_currentSearch == value)
        return;

    m_currentSearch = value;
    emit currentSearchChanged();
}

QString NavigationViewModel::searchScope() const
{
    return m_searchScope;
}

void NavigationViewModel::setSearchScope(const QString& value)
{
    const QString resolved = (value == QStringLiteral("global"))
    ? QStringLiteral("global")
    : QStringLiteral("folder");

    if (m_searchScope == resolved)
        return;

    m_searchScope = resolved;
    emit searchScopeChanged();
}

bool NavigationViewModel::canGoBack() const
{
    return true;
}

bool NavigationViewModel::canGoForward() const
{
    return true;
}

bool NavigationViewModel::canGoUp() const
{
    return m_breadcrumbModel.rowCount() > 1;
}

void NavigationViewModel::goBack()
{
    invokeBackendNoArgs("goBack");
}

void NavigationViewModel::goForward()
{
    invokeBackendNoArgs("goForward");
}

void NavigationViewModel::goUp()
{
    if (m_backend)
    {
        invokeBackendNoArgs("goUp");
        return;
    }

    auto items = m_breadcrumbModel.items();
    if (items.size() <= 1)
        return;

    items.removeLast();
    m_breadcrumbModel.setItems(items);

    syncPathTextFromBreadcrumbs();
    emit navigationStateChanged();
}

void NavigationViewModel::refresh()
{
    invokeBackendNoArgs("refresh");
}

void NavigationViewModel::beginPathEdit()
{
    setEditingPath(true);
}

void NavigationViewModel::cancelPathEdit()
{
    setEditingPath(false);
    syncPathTextFromBreadcrumbs();
}

void NavigationViewModel::commitPathEdit(const QString& text)
{
    const QString normalized = normalizedPathText(text);
    if (normalized.isEmpty())
    {
        setEditingPath(false);
        return;
    }

    if (m_backend)
    {
        invokeBackendOneStringArg("navigateToPathString", normalized);
    }
    else
    {
        setBreadcrumbsFromPathText(normalized);
    }

    m_pathText = normalized;
    emit pathTextChanged();

    setEditingPath(false);
    emit navigationStateChanged();
}

void NavigationViewModel::navigateToBreadcrumb(int index)
{
    if (index < 0 || index >= m_breadcrumbModel.rowCount())
        return;

    if (m_backend)
    {
        QVariant returnedValue;
        QMetaObject::invokeMethod(
            m_backend,
            "copyBreadcrumbPath",
            Qt::DirectConnection,
            Q_RETURN_ARG(QVariant, returnedValue),
            Q_ARG(int, index));

        if (m_backend->metaObject()->indexOfMethod("navigateToPathParts(QVariantList)") >= 0)
        {
            QVariantList parts;
            const auto items = m_breadcrumbModel.items();
            for (int i = 0; i <= index; ++i)
            {
                QVariantMap item;
                item.insert(QStringLiteral("label"), items.at(i).label);
                item.insert(QStringLiteral("icon"), items.at(i).icon);
                item.insert(QStringLiteral("path"), items.at(i).path);
                parts.push_back(item);
            }

            QMetaObject::invokeMethod(
                m_backend,
                "navigateToPathParts",
                Qt::DirectConnection,
                Q_ARG(QVariantList, parts));
        }
    }
    else
    {
        auto items = m_breadcrumbModel.items();
        items.resize(index + 1);
        m_breadcrumbModel.setItems(items);
        syncPathTextFromBreadcrumbs();
    }

    setEditingPath(false);
    emit navigationStateChanged();
}

void NavigationViewModel::submitSearch()
{
    invokeBackendSearch();
}

void NavigationViewModel::setBreadcrumbsFromPathText(const QString& text)
{
    const QString normalized = normalizedPathText(text);
    const QStringList parts = normalized.split('/', Qt::SkipEmptyParts);

    QVector<NavigationBreadcrumbModel::Item> items;
    items.reserve(parts.size());

    QString cumulativePath;
    for (int i = 0; i < parts.size(); ++i)
    {
        NavigationBreadcrumbModel::Item item;
        item.label = parts.at(i);
        item.icon = (i == 0 && item.label.contains(':'))
                        ? QStringLiteral("hard-drive")
                        : QStringLiteral("folder");

        if (i == 0)
            cumulativePath = item.label;
        else
            cumulativePath += QStringLiteral("/") + item.label;

        item.path = cumulativePath;
        items.push_back(item);
    }

    m_breadcrumbModel.setItems(items);
    syncPathTextFromBreadcrumbs();
}

void NavigationViewModel::seedDefaultBreadcrumbsIfEmpty()
{
    if (m_breadcrumbModel.rowCount() > 0)
        return;

    QVector<NavigationBreadcrumbModel::Item> items;
    items.push_back({ QStringLiteral("C:"), QStringLiteral("hard-drive"), QStringLiteral("C:") });
    items.push_back({ QStringLiteral("Projects"), QStringLiteral("folder"), QStringLiteral("C:/Projects") });
    items.push_back({ QStringLiteral("Findex"), QStringLiteral("folder"), QStringLiteral("C:/Projects/Findex") });
    m_breadcrumbModel.setItems(items);
}

QString NavigationViewModel::normalizedPathText(const QString& text) const
{
    QString value = text.trimmed();
    value.replace('\\', '/');

    while (value.contains("//"))
        value.replace("//", "/");

    return value;
}

void NavigationViewModel::syncPathTextFromBreadcrumbs()
{
    const auto items = m_breadcrumbModel.items();
    if (items.isEmpty())
    {
        if (!m_pathText.isEmpty())
        {
            m_pathText.clear();
            emit pathTextChanged();
        }
        return;
    }

    const QString next = items.last().path;

    if (m_pathText == next)
        return;

    m_pathText = next;
    emit pathTextChanged();
}

void NavigationViewModel::invokeBackendNoArgs(const char* methodName)
{
    if (!m_backend)
        return;

    QMetaObject::invokeMethod(m_backend, methodName, Qt::DirectConnection);
}

void NavigationViewModel::invokeBackendOneStringArg(const char* methodName, const QString& value)
{
    if (!m_backend)
        return;

    QMetaObject::invokeMethod(
        m_backend,
        methodName,
        Qt::DirectConnection,
        Q_ARG(QString, value));
}

void NavigationViewModel::invokeBackendSearch()
{
    if (!m_backend)
        return;

    QMetaObject::invokeMethod(
        m_backend,
        "search",
        Qt::DirectConnection,
        Q_ARG(QString, m_currentSearch),
        Q_ARG(QString, m_searchScope));
}