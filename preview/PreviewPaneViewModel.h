#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

class PreviewPaneViewModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool previewEnabled READ previewEnabled WRITE setPreviewEnabled NOTIFY previewEnabledChanged)

    Q_PROPERTY(int previewPaneWidth READ previewPaneWidth WRITE setPreviewPaneWidth NOTIFY previewPaneWidthChanged)
    Q_PROPERTY(int previewPaneMinWidth READ previewPaneMinWidth WRITE setPreviewPaneMinWidth NOTIFY previewPaneMinWidthChanged)
    Q_PROPERTY(int previewPaneMaxWidth READ previewPaneMaxWidth WRITE setPreviewPaneMaxWidth NOTIFY previewPaneMaxWidthChanged)
    Q_PROPERTY(int previewPaneLastExpandedWidth READ previewPaneLastExpandedWidth WRITE setPreviewPaneLastExpandedWidth NOTIFY previewPaneLastExpandedWidthChanged)

    Q_PROPERTY(bool visible READ visible NOTIFY previewChanged)
    Q_PROPERTY(QString name READ name NOTIFY previewChanged)
    Q_PROPERTY(QString type READ type NOTIFY previewChanged)
    Q_PROPERTY(QString icon READ icon NOTIFY previewChanged)
    Q_PROPERTY(QString nativeIconSource READ nativeIconSource NOTIFY previewChanged)
    Q_PROPERTY(QString previewType READ previewType NOTIFY previewChanged)
    Q_PROPERTY(QString size READ size NOTIFY previewChanged)
    Q_PROPERTY(QString dateModified READ dateModified NOTIFY previewChanged)
    Q_PROPERTY(QString summary READ summary NOTIFY previewChanged)
    Q_PROPERTY(QStringList lines READ lines NOTIFY previewChanged)

public:
    explicit PreviewPaneViewModel(QObject* parent = nullptr);

    bool previewEnabled() const;
    void setPreviewEnabled(bool value);

    int previewPaneWidth() const;
    void setPreviewPaneWidth(int value);

    int previewPaneMinWidth() const;
    void setPreviewPaneMinWidth(int value);

    int previewPaneMaxWidth() const;
    void setPreviewPaneMaxWidth(int value);

    int previewPaneLastExpandedWidth() const;
    void setPreviewPaneLastExpandedWidth(int value);

    bool visible() const;
    QString name() const;
    QString type() const;
    QString icon() const;
    QString nativeIconSource() const;
    QString previewType() const;
    QString size() const;
    QString dateModified() const;
    QString summary() const;
    QStringList lines() const;

    Q_INVOKABLE void showPreviewData(const QVariantMap& data);
    Q_INVOKABLE void clearPreview();
    Q_INVOKABLE void togglePreviewEnabled();

signals:
    void previewEnabledChanged();
    void previewPaneWidthChanged();
    void previewPaneMinWidthChanged();
    void previewPaneMaxWidthChanged();
    void previewPaneLastExpandedWidthChanged();
    void previewChanged();

private:
    void setPreviewFields(
        bool visible,
        const QString& name,
        const QString& type,
        const QString& icon,
        const QString& nativeIconSource,
        const QString& previewType,
        const QString& size,
        const QString& dateModified,
        const QString& summary,
        const QStringList& lines);

private:
    bool m_previewEnabled = true;

    int m_previewPaneWidth = 320;
    int m_previewPaneMinWidth = 220;
    int m_previewPaneMaxWidth = 420;
    int m_previewPaneLastExpandedWidth = 320;

    bool m_visible = false;
    QString m_name;
    QString m_type;
    QString m_icon = QStringLiteral("insert-drive-file");
    QString m_nativeIconSource;
    QString m_previewType = QStringLiteral("none");
    QString m_size;
    QString m_dateModified;
    QString m_summary;
    QStringList m_lines;
};