#include "navigation/NavigationViewModel.h"

#include <QMetaObject>
#include <QVariant>
#include <QStringList>
#include <QDir>
#include <QRegularExpression>

namespace
{
QString normalizePathSeparators(QString value)
{
    value = value.trimmed();
    value.replace('\\', '/');

#ifdef Q_OS_WINDOWS
    const bool isUncPath =
        value.startsWith(QStringLiteral("//"))
        && !value.startsWith(QStringLiteral("///"));

    if (isUncPath) {
        QString tail = value.mid(2);
        while (tail.contains(QStringLiteral("//")))
            tail.replace(QStringLiteral("//"), QStringLiteral("/"));

        return QStringLiteral("//") + tail;
    }
#endif

    while (value.contains(QStringLiteral("//")))
        value.replace(QStringLiteral("//"), QStringLiteral("/"));

    return value;
}

bool isWindowsDriveRootPath(const QString& value)
{
    static const QRegularExpression re(QStringLiteral("^[A-Za-z]:/$"));
    return re.match(value).hasMatch();
}

bool isWindowsDriveToken(const QString& value)
{
    static const QRegularExpression re(QStringLiteral("^[A-Za-z]:$"));
    return re.match(value).hasMatch();
}
}

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

void NavigationViewModel::updatePathText(const QString& text)
{
    const QString normalized = normalizedPathText(text);

    if (m_pathText == normalized)
        return;

    m_pathText = normalized;
    emit pathTextChanged();
    emit pathEdited(m_pathText);
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

    if (m_pathText != normalized)
    {
        m_pathText = normalized;
        emit pathTextChanged();
    }

    setEditingPath(false);
    emit navigationStateChanged();
    emit pathCommitted(normalized);
}

void NavigationViewModel::navigateToBreadcrumb(int index)
{
    if (index < 0 || index >= m_breadcrumbModel.rowCount())
        return;

    const auto items = m_breadcrumbModel.items();
    if (index < 0 || index >= items.size())
        return;

    const QString targetPath = normalizedPathText(items.at(index).path);
    if (targetPath.isEmpty())
        return;

    if (m_backend)
        invokeBackendOneStringArg("navigateToPathString", targetPath);
    else
    {
        auto resizedItems = items;
        resizedItems.resize(index + 1);
        m_breadcrumbModel.setItems(resizedItems);
        syncPathTextFromBreadcrumbs();
    }

    setEditingPath(false);
    emit navigationStateChanged();
}

void NavigationViewModel::setPathFromBackend(const QString& text)
{
    const QString normalized = normalizedPathText(text);
    if (normalized.isEmpty())
        return;

    setBreadcrumbsFromPathText(normalized);

    if (m_pathText != normalized)
    {
        m_pathText = normalized;
        emit pathTextChanged();
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
    if (normalized.isEmpty())
    {
        m_breadcrumbModel.clear();
        syncPathTextFromBreadcrumbs();
        return;
    }

    QVector<NavigationBreadcrumbModel::Item> items;

#ifdef Q_OS_WINDOWS
    QString working = normalized;
    if (isWindowsDriveRootPath(working))
    {
        const QString driveLabel = working.left(2);
        items.push_back({
            driveLabel,
            QStringLiteral("hard-drive"),
            working
        });

        m_breadcrumbModel.setItems(items);
        syncPathTextFromBreadcrumbs();
        return;
    }

    static const QRegularExpression drivePrefixRe(QStringLiteral("^([A-Za-z]:)(/.*)?$"));
    const QRegularExpressionMatch driveMatch = drivePrefixRe.match(working);
    if (driveMatch.hasMatch())
    {
        const QString driveLabel = driveMatch.captured(1);
        const QString tail = driveMatch.captured(2);

        items.push_back({
            driveLabel,
            QStringLiteral("hard-drive"),
            driveLabel + QStringLiteral("/")
        });

        const QStringList parts = tail.split('/', Qt::SkipEmptyParts);
        QString cumulativePath = driveLabel + QStringLiteral("/");

        for (const QString& part : parts)
        {
            if (!cumulativePath.endsWith('/'))
                cumulativePath += QStringLiteral("/");

            cumulativePath += part;

            items.push_back({
                part,
                QStringLiteral("folder"),
                cumulativePath
            });
        }

        m_breadcrumbModel.setItems(items);
        syncPathTextFromBreadcrumbs();
        return;
    }

    const bool isUncPath =
        working.startsWith(QStringLiteral("//"))
        && !working.startsWith(QStringLiteral("///"));

    if (isUncPath)
    {
        const QStringList parts = working.mid(2).split('/', Qt::SkipEmptyParts);
        QString cumulativePath = QStringLiteral("//");

        for (int i = 0; i < parts.size(); ++i)
        {
            if (i > 0)
                cumulativePath += QStringLiteral("/");

            cumulativePath += parts.at(i);

            items.push_back({
                parts.at(i),
                i == 0 ? QStringLiteral("hard-drive") : QStringLiteral("folder"),
                cumulativePath
            });
        }

        m_breadcrumbModel.setItems(items);
        syncPathTextFromBreadcrumbs();
        return;
    }
#endif

    const QStringList parts = normalized.split('/', Qt::SkipEmptyParts);
    QString cumulativePath;

    for (int i = 0; i < parts.size(); ++i)
    {
        NavigationBreadcrumbModel::Item item;
        item.label = parts.at(i);
        item.icon = (i == 0) ? QStringLiteral("hard-drive") : QStringLiteral("folder");

        if (i == 0)
            cumulativePath = QStringLiteral("/") + item.label;
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
    items.push_back({ QStringLiteral("C:"), QStringLiteral("hard-drive"), QStringLiteral("C:/") });
    items.push_back({ QStringLiteral("Projects"), QStringLiteral("folder"), QStringLiteral("C:/Projects") });
    items.push_back({ QStringLiteral("Findex"), QStringLiteral("folder"), QStringLiteral("C:/Projects/Findex") });
    m_breadcrumbModel.setItems(items);
}

QString NavigationViewModel::normalizedPathText(const QString& text) const
{
    QString value = normalizePathSeparators(text);
    if (value.isEmpty())
        return value;

#ifdef Q_OS_WINDOWS
    if (isWindowsDriveToken(value))
        value += QStringLiteral("/");

    static const QRegularExpression driveRootRe(QStringLiteral("^([A-Za-z]:)/?$"));
    const QRegularExpressionMatch driveRootMatch = driveRootRe.match(value);
    if (driveRootMatch.hasMatch())
        return driveRootMatch.captured(1) + QStringLiteral("/");
#endif

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

    const QString next = normalizedPathText(items.last().path);

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