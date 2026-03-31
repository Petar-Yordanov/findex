#include "toolbar/CommandBarViewModel.h"

#include <QMetaObject>

CommandBarViewModel::CommandBarViewModel(QObject* parent)
    : QObject(parent)
{
}

QObject* CommandBarViewModel::backend() const
{
    return m_backend;
}

void CommandBarViewModel::setBackend(QObject* backend)
{
    if (m_backend == backend)
        return;

    m_backend = backend;
    emit backendChanged();

    if (!m_backend)
        return;

    if (hasMethod("savedTheme()"))
    {
        QString value;
        QMetaObject::invokeMethod(
            m_backend,
            "savedTheme",
            Qt::DirectConnection,
            Q_RETURN_ARG(QString, value));
        setThemeMode(value);
    }

    if (hasMethod("savedViewMode()"))
    {
        QString value;
        QMetaObject::invokeMethod(
            m_backend,
            "savedViewMode",
            Qt::DirectConnection,
            Q_RETURN_ARG(QString, value));
        setViewMode(value);
    }

    if (hasMethod("savedShowHiddenFiles()"))
    {
        bool value = false;
        QMetaObject::invokeMethod(
            m_backend,
            "savedShowHiddenFiles",
            Qt::DirectConnection,
            Q_RETURN_ARG(bool, value));
        setShowHiddenFiles(value);
    }
}

QString CommandBarViewModel::themeMode() const
{
    return m_themeMode;
}

void CommandBarViewModel::setThemeMode(const QString& value)
{
    const QString resolved = value.trimmed().isEmpty()
    ? QStringLiteral("Light")
    : value.trimmed();

    if (m_themeMode == resolved)
        return;

    m_themeMode = resolved;
    emit themeModeChanged();
}

QString CommandBarViewModel::viewMode() const
{
    return m_viewMode;
}

void CommandBarViewModel::setViewMode(const QString& value)
{
    const QString resolved = value.trimmed().isEmpty()
    ? QStringLiteral("Details")
    : value.trimmed();

    if (m_viewMode == resolved)
        return;

    m_viewMode = resolved;
    emit viewModeChanged();
}

bool CommandBarViewModel::showHiddenFiles() const
{
    return m_showHiddenFiles;
}

void CommandBarViewModel::setShowHiddenFiles(bool value)
{
    if (m_showHiddenFiles == value)
        return;

    m_showHiddenFiles = value;
    emit showHiddenFilesChanged();
}

void CommandBarViewModel::createFolder()
{
    invokeNoArgs("createFolder");
}

void CommandBarViewModel::createFile()
{
    invokeNoArgs("createFile");
}

void CommandBarViewModel::cutSelection()
{
    if (!m_backend)
        return;

    if (hasMethod("cutSelectedItems()"))
    {
        invokeNoArgs("cutSelectedItems");
        return;
    }

    if (hasMethod("cutItems()"))
        invokeNoArgs("cutItems");
}

void CommandBarViewModel::copySelection()
{
    if (!m_backend)
        return;

    if (hasMethod("copySelectedItems()"))
    {
        invokeNoArgs("copySelectedItems");
        return;
    }

    if (hasMethod("copyItems()"))
        invokeNoArgs("copyItems");
}

void CommandBarViewModel::paste()
{
    invokeNoArgs("pasteItems");
}

void CommandBarViewModel::renameSelection()
{
    if (!m_backend)
        return;

    if (hasMethod("renameSelectedItems()"))
    {
        invokeNoArgs("renameSelectedItems");
        return;
    }

    if (hasMethod("beginRenameSelectedItem()"))
        invokeNoArgs("beginRenameSelectedItem");
}

void CommandBarViewModel::deleteSelection()
{
    if (!m_backend)
        return;

    if (hasMethod("deleteSelectedItems()"))
    {
        invokeNoArgs("deleteSelectedItems");
        return;
    }

    if (hasMethod("deleteItems()"))
        invokeNoArgs("deleteItems");
}

void CommandBarViewModel::refresh()
{
    invokeNoArgs("refresh");
}

void CommandBarViewModel::compressSelection()
{
    if (!m_backend)
        return;

    if (hasMethod("compressSelectedItems()"))
    {
        invokeNoArgs("compressSelectedItems");
        return;
    }

    if (hasMethod("compressItems()"))
        invokeNoArgs("compressItems");
}

void CommandBarViewModel::extractSelection()
{
    if (!m_backend)
        return;

    if (hasMethod("extractSelectedItems()"))
    {
        invokeNoArgs("extractSelectedItems");
        return;
    }

    if (hasMethod("extractItems()"))
        invokeNoArgs("extractItems");
}

void CommandBarViewModel::selectAll()
{
    if (!m_backend)
        return;

    if (hasMethod("selectAll()"))
    {
        invokeNoArgs("selectAll");
        return;
    }

    if (hasMethod("selectAllItems()"))
        invokeNoArgs("selectAllItems");
}

void CommandBarViewModel::showProperties()
{
    if (!m_backend)
        return;

    if (hasMethod("showProperties()"))
    {
        invokeNoArgs("showProperties");
        return;
    }

    if (hasMethod("showItemProperties()"))
    {
        invokeNoArgs("showItemProperties");
        return;
    }

    if (hasMethod("showCurrentLocationProperties()"))
        invokeNoArgs("showCurrentLocationProperties");
}

void CommandBarViewModel::applyTheme(const QString& mode)
{
    const QString resolved = mode.trimmed().isEmpty()
    ? QStringLiteral("Light")
    : mode.trimmed();

    setThemeMode(resolved);

    if (!m_backend)
        return;

    if (hasMethod("setTheme(QString)"))
    {
        QMetaObject::invokeMethod(
            m_backend,
            "setTheme",
            Qt::DirectConnection,
            Q_ARG(QString, resolved));
        return;
    }

    if (hasMethod("setAppTheme(QString)"))
    {
        QMetaObject::invokeMethod(
            m_backend,
            "setAppTheme",
            Qt::DirectConnection,
            Q_ARG(QString, resolved));
    }
}

void CommandBarViewModel::applyViewMode(const QString& mode)
{
    const QString resolved = mode.trimmed().isEmpty()
    ? QStringLiteral("Details")
    : mode.trimmed();

    setViewMode(resolved);

    if (!m_backend)
        return;

    if (hasMethod("setViewMode(QString)"))
    {
        QMetaObject::invokeMethod(
            m_backend,
            "setViewMode",
            Qt::DirectConnection,
            Q_ARG(QString, resolved));
        return;
    }

    if (hasMethod("changeViewMode(QString)"))
    {
        QMetaObject::invokeMethod(
            m_backend,
            "changeViewMode",
            Qt::DirectConnection,
            Q_ARG(QString, resolved));
    }
}

void CommandBarViewModel::toggleHiddenFiles()
{
    const bool next = !m_showHiddenFiles;
    setShowHiddenFiles(next);

    if (!m_backend)
        return;

    if (hasMethod("setShowHiddenFiles(bool)"))
    {
        QMetaObject::invokeMethod(
            m_backend,
            "setShowHiddenFiles",
            Qt::DirectConnection,
            Q_ARG(bool, next));
        return;
    }

    if (hasMethod("showHiddenFiles(bool)"))
    {
        QMetaObject::invokeMethod(
            m_backend,
            "showHiddenFiles",
            Qt::DirectConnection,
            Q_ARG(bool, next));
    }
}

void CommandBarViewModel::invokeNoArgs(const char* methodName)
{
    if (!m_backend)
        return;

    QMetaObject::invokeMethod(m_backend, methodName, Qt::DirectConnection);
}

bool CommandBarViewModel::hasMethod(const char* signature) const
{
    if (!m_backend)
        return false;

    return m_backend->metaObject()->indexOfMethod(signature) >= 0;
}