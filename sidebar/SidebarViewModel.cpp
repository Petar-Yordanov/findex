#include "SidebarViewModel.h"

#include <QDebug>

#include "SidebarTreeModel.h"
#include "DriveListModel.h"

SidebarViewModel::SidebarViewModel(QObject* parent)
    : QObject(parent)
    , m_treeModel(new SidebarTreeModel(this))
    , m_drivesModel(new DriveListModel(this))
{
    qDebug() << "SidebarViewModel ctor:";
    qDebug() << "  m_treeModel   =" << m_treeModel;
    qDebug() << "  m_drivesModel =" << m_drivesModel;
}

QObject* SidebarViewModel::treeModel() const
{
    qDebug() << "SidebarViewModel::treeModel() ->" << m_treeModel;
    return m_treeModel;
}

QObject* SidebarViewModel::drivesModel() const
{
    qDebug() << "SidebarViewModel::drivesModel() ->" << m_drivesModel;
    return m_drivesModel;
}

QString SidebarViewModel::contextLabel() const
{
    return m_contextLabel;
}

QString SidebarViewModel::contextIcon() const
{
    return m_contextIcon;
}

QString SidebarViewModel::contextKind() const
{
    return m_contextKind;
}

QString SidebarViewModel::hoveredLabel() const
{
    return m_hoveredLabel;
}

QString SidebarViewModel::hoveredKind() const
{
    return m_hoveredKind;
}

void SidebarViewModel::openLocation(const QString& label, const QString& icon, const QString& kind)
{
    m_selectedLabel = label;
    m_selectedKind = kind;
    emit openRequested(label, icon, kind);
}

void SidebarViewModel::setContextItem(const QString& label, const QString& icon, const QString& kind)
{
    if (m_contextLabel == label && m_contextIcon == icon && m_contextKind == kind)
        return;

    m_contextLabel = label;
    m_contextIcon = icon;
    m_contextKind = kind;
    emit contextChanged();
}

bool SidebarViewModel::isSelected(const QString& label, const QString& kind) const
{
    return m_selectedLabel == label && m_selectedKind == kind;
}

void SidebarViewModel::setHoveredItem(const QString& label, const QString& kind)
{
    if (m_hoveredLabel == label && m_hoveredKind == kind)
        return;

    m_hoveredLabel = label;
    m_hoveredKind = kind;
    emit hoveredChanged();
}

void SidebarViewModel::clearHoveredItem(const QString& label, const QString& kind)
{
    if (m_hoveredLabel != label || m_hoveredKind != kind)
        return;

    m_hoveredLabel.clear();
    m_hoveredKind.clear();
    emit hoveredChanged();
}

bool SidebarViewModel::isHovered(const QString& label, const QString& kind) const
{
    return m_hoveredLabel == label && m_hoveredKind == kind;
}

void SidebarViewModel::requestOpenContextInNewTab()
{
    if (m_contextLabel.isEmpty())
        return;

    emit openInNewTabRequested(m_contextLabel, m_contextIcon, m_contextKind);
}

void SidebarViewModel::requestCopyContextPath()
{
    if (m_contextLabel.isEmpty())
        return;

    emit copyPathRequested(m_contextLabel, m_contextKind);
}

void SidebarViewModel::requestPinContext()
{
    if (m_contextLabel.isEmpty())
        return;

    emit pinRequested(m_contextLabel, m_contextKind);
}

void SidebarViewModel::requestContextProperties()
{
    if (m_contextLabel.isEmpty())
        return;

    emit propertiesRequested(m_contextLabel, m_contextKind);
}