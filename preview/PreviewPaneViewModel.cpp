#include "preview/PreviewPaneViewModel.h"

PreviewPaneViewModel::PreviewPaneViewModel(QObject* parent)
    : QObject(parent)
{
}

bool PreviewPaneViewModel::previewEnabled() const
{
    return m_previewEnabled;
}

void PreviewPaneViewModel::setPreviewEnabled(bool value)
{
    if (m_previewEnabled == value)
        return;

    m_previewEnabled = value;

    if (m_previewEnabled) {
        if (m_previewPaneLastExpandedWidth >= m_previewPaneMinWidth
            && m_previewPaneWidth < m_previewPaneMinWidth) {
            m_previewPaneWidth = m_previewPaneLastExpandedWidth;
            emit previewPaneWidthChanged();
        }
    } else {
        if (m_previewPaneWidth >= m_previewPaneMinWidth) {
            m_previewPaneLastExpandedWidth = m_previewPaneWidth;
            emit previewPaneLastExpandedWidthChanged();
        }
    }

    emit previewEnabledChanged();
}

int PreviewPaneViewModel::previewPaneWidth() const
{
    return m_previewPaneWidth;
}

void PreviewPaneViewModel::setPreviewPaneWidth(int value)
{
    if (value < 0)
        value = 0;

    if (m_previewPaneWidth == value)
        return;

    m_previewPaneWidth = value;

    if (m_previewEnabled && m_previewPaneWidth >= m_previewPaneMinWidth
        && m_previewPaneLastExpandedWidth != m_previewPaneWidth) {
        m_previewPaneLastExpandedWidth = m_previewPaneWidth;
        emit previewPaneLastExpandedWidthChanged();
    }

    emit previewPaneWidthChanged();
}

int PreviewPaneViewModel::previewPaneMinWidth() const
{
    return m_previewPaneMinWidth;
}

void PreviewPaneViewModel::setPreviewPaneMinWidth(int value)
{
    if (value < 0)
        value = 0;

    if (m_previewPaneMinWidth == value)
        return;

    m_previewPaneMinWidth = value;
    emit previewPaneMinWidthChanged();
}

int PreviewPaneViewModel::previewPaneMaxWidth() const
{
    return m_previewPaneMaxWidth;
}

void PreviewPaneViewModel::setPreviewPaneMaxWidth(int value)
{
    if (value < 0)
        value = 0;

    if (m_previewPaneMaxWidth == value)
        return;

    m_previewPaneMaxWidth = value;
    emit previewPaneMaxWidthChanged();
}

int PreviewPaneViewModel::previewPaneLastExpandedWidth() const
{
    return m_previewPaneLastExpandedWidth;
}

void PreviewPaneViewModel::setPreviewPaneLastExpandedWidth(int value)
{
    if (value < 0)
        value = 0;

    if (m_previewPaneLastExpandedWidth == value)
        return;

    m_previewPaneLastExpandedWidth = value;
    emit previewPaneLastExpandedWidthChanged();
}

bool PreviewPaneViewModel::visible() const
{
    return m_visible;
}

QString PreviewPaneViewModel::name() const
{
    return m_name;
}

QString PreviewPaneViewModel::type() const
{
    return m_type;
}

QString PreviewPaneViewModel::icon() const
{
    return m_icon;
}

QString PreviewPaneViewModel::nativeIconSource() const
{
    return m_nativeIconSource;
}

QString PreviewPaneViewModel::previewType() const
{
    return m_previewType;
}

QString PreviewPaneViewModel::size() const
{
    return m_size;
}

QString PreviewPaneViewModel::dateModified() const
{
    return m_dateModified;
}

QString PreviewPaneViewModel::summary() const
{
    return m_summary;
}

QStringList PreviewPaneViewModel::lines() const
{
    return m_lines;
}

void PreviewPaneViewModel::showPreviewData(const QVariantMap& data)
{
    if (data.isEmpty()) {
        clearPreview();
        return;
    }

    QStringList nextLines;
    const QVariant rawLines = data.value(QStringLiteral("lines"));
    if (rawLines.canConvert<QStringList>()) {
        nextLines = rawLines.toStringList();
    } else {
        const QVariantList list = rawLines.toList();
        for (const QVariant& item : list)
            nextLines.push_back(item.toString());
    }

    setPreviewFields(
        data.value(QStringLiteral("visible"), true).toBool(),
        data.value(QStringLiteral("name")).toString(),
        data.value(QStringLiteral("type")).toString(),
        data.value(QStringLiteral("icon"), QStringLiteral("insert-drive-file")).toString(),
        data.value(QStringLiteral("nativeIconSource")).toString(),
        data.value(QStringLiteral("previewType"), QStringLiteral("none")).toString(),
        data.value(QStringLiteral("size")).toString(),
        data.value(QStringLiteral("dateModified")).toString(),
        data.value(QStringLiteral("summary")).toString(),
        nextLines);
}

void PreviewPaneViewModel::clearPreview()
{
    setPreviewFields(
        false,
        QString(),
        QString(),
        QStringLiteral("insert-drive-file"),
        QString(),
        QStringLiteral("none"),
        QString(),
        QString(),
        QString(),
        {});
}

void PreviewPaneViewModel::togglePreviewEnabled()
{
    setPreviewEnabled(!m_previewEnabled);
}

void PreviewPaneViewModel::setPreviewFields(
    bool visibleValue,
    const QString& nameValue,
    const QString& typeValue,
    const QString& iconValue,
    const QString& nativeIconSourceValue,
    const QString& previewTypeValue,
    const QString& sizeValue,
    const QString& dateModifiedValue,
    const QString& summaryValue,
    const QStringList& linesValue)
{
    const bool changed =
        m_visible != visibleValue
        || m_name != nameValue
        || m_type != typeValue
        || m_icon != iconValue
        || m_nativeIconSource != nativeIconSourceValue
        || m_previewType != previewTypeValue
        || m_size != sizeValue
        || m_dateModified != dateModifiedValue
        || m_summary != summaryValue
        || m_lines != linesValue;

    if (!changed)
        return;

    m_visible = visibleValue;
    m_name = nameValue;
    m_type = typeValue;
    m_icon = iconValue;
    m_nativeIconSource = nativeIconSourceValue;
    m_previewType = previewTypeValue;
    m_size = sizeValue;
    m_dateModified = dateModifiedValue;
    m_summary = summaryValue;
    m_lines = linesValue;

    emit previewChanged();
}