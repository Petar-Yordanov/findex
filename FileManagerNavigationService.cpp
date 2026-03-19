#include "FileManagerNavigationService.h"

FileManagerNavigationService::FileManagerNavigationService(QObject* parent)
    : QObject(parent)
    , m_pathParts(QStringList{QStringLiteral("C:"), QStringLiteral("Projects"), QStringLiteral("Qt")})
    , m_history(QStringList{QStringLiteral("C:/Projects/Qt")})
    , m_historyIndex(0)
{
}

QVariantMap FileManagerNavigationService::makePathPart(const QString& label, const QString& icon) const
{
    return QVariantMap{
        {"label", label},
        {"icon", icon}
    };
}

QStringList FileManagerNavigationService::parsePath(const QString& pathText) const
{
    QString normalized = pathText.trimmed();
    normalized.replace('\\', '/');
    const QStringList parts = normalized.split('/', Qt::SkipEmptyParts);
    return parts.isEmpty() ? m_pathParts : parts;
}

QString FileManagerNavigationService::toPathText(const QStringList& parts) const
{
    if (parts.isEmpty())
        return {};

    if (parts.first().size() == 2 && parts.first().endsWith(':'))
        return parts.first() + "/" + parts.mid(1).join('/');

    return parts.join('/');
}

void FileManagerNavigationService::pushHistory(const QString& pathText)
{
    if (pathText.isEmpty())
        return;

    while (m_history.size() - 1 > m_historyIndex)
        m_history.removeLast();

    if (m_history.isEmpty() || m_history.last() != pathText) {
        m_history.append(pathText);
        m_historyIndex = m_history.size() - 1;
    }
}

QVariantList FileManagerNavigationService::pathParts() const
{
    QVariantList out;
    for (int i = 0; i < m_pathParts.size(); ++i) {
        const QString& part = m_pathParts[i];
        const QString icon =
            (i == 0 && part == QStringLiteral("Home")) ? QStringLiteral("home")
            : (i == 0 && part.endsWith(':')) ? QStringLiteral("hard-drive")
                                                       : QStringLiteral("folder");
        out.append(makePathPart(part, icon));
    }
    return out;
}

QString FileManagerNavigationService::pathText() const
{
    return toPathText(m_pathParts);
}

void FileManagerNavigationService::navigateToPathString(const QString& pathText)
{
    m_pathParts = parsePath(pathText);
    pushHistory(toPathText(m_pathParts));
}

void FileManagerNavigationService::navigateToPathParts(const QVariantList& parts)
{
    QStringList out;
    for (const auto& item : parts)
        out.append(item.toMap().value("label").toString());

    if (!out.isEmpty()) {
        m_pathParts = out;
        pushHistory(toPathText(m_pathParts));
    }
}

void FileManagerNavigationService::openSidebarLocation(const QString& label, const QString& kind)
{
    if (kind == QStringLiteral("drive")) {
        const int start = label.indexOf('(');
        const int end = label.indexOf(')');
        if (start >= 0 && end > start)
            navigateToPathString(label.mid(start + 1, end - start - 1));
        return;
    }

    navigateToPathString(label);
}

void FileManagerNavigationService::appendPathSegment(const QString& segment)
{
    if (segment.trimmed().isEmpty())
        return;

    m_pathParts.append(segment.trimmed());
    pushHistory(toPathText(m_pathParts));
}

void FileManagerNavigationService::goBack()
{
    if (m_historyIndex <= 0)
        return;

    --m_historyIndex;
    m_pathParts = parsePath(m_history[m_historyIndex]);
}

void FileManagerNavigationService::goForward()
{
    if (m_historyIndex < 0 || m_historyIndex >= m_history.size() - 1)
        return;

    ++m_historyIndex;
    m_pathParts = parsePath(m_history[m_historyIndex]);
}

void FileManagerNavigationService::goUp()
{
    if (m_pathParts.size() > 1) {
        m_pathParts.removeLast();
        pushHistory(toPathText(m_pathParts));
    }
}