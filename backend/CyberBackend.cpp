#include "CyberBackend.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QtNetwork/QHostAddress>
#include <QtNetwork/QNetworkAddressEntry>

namespace {
QString targetDirectoryPath() {
    const QString home = QDir::homePath();
    const QString hyprdarkPath = home + QStringLiteral("/.local/share/hyprdark");
    QDir().mkpath(hyprdarkPath);
    return hyprdarkPath;
}
}

CyberBackend::CyberBackend(QObject *parent)
    : QObject(parent)
{
    m_targetFilePath = resolveTargetFilePath();
    setupTargetWatcher();
    reloadTargetIp();

    setupVpnMonitor();
    updateVpnStatus();
}

QString CyberBackend::targetIp() const {
    return m_targetIp;
}

bool CyberBackend::hasTarget() const {
    return m_hasTarget;
}

QString CyberBackend::vpnIp() const {
    return m_vpnIp;
}

QString CyberBackend::vpnInterface() const {
    return m_vpnInterface;
}

bool CyberBackend::vpnConnected() const {
    return m_vpnConnected;
}

QString CyberBackend::resolveTargetFilePath() const {
    return targetDirectoryPath() + QStringLiteral("/target_ip");
}

void CyberBackend::setupTargetWatcher() {
    const QString dirPath = targetDirectoryPath();
    if (QDir(dirPath).exists()) {
        m_targetWatcher.addPath(dirPath);
    }

    if (QFile::exists(m_targetFilePath)) {
        m_targetWatcher.addPath(m_targetFilePath);
    }

    connect(&m_targetWatcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
        if (path == m_targetFilePath) {
            reloadTargetIp();
            if (QFile::exists(m_targetFilePath) && !m_targetWatcher.files().contains(m_targetFilePath)) {
                m_targetWatcher.addPath(m_targetFilePath);
            }
        }
    });

    connect(&m_targetWatcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString &path) {
        if (path == targetDirectoryPath()) {
            reloadTargetIp();
            if (QFile::exists(m_targetFilePath) && !m_targetWatcher.files().contains(m_targetFilePath)) {
                m_targetWatcher.addPath(m_targetFilePath);
            }
        }
    });
}

void CyberBackend::reloadTargetIp() {
    QString newIp;
    bool hasTarget = false;

    QFile file(m_targetFilePath);
    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        newIp = QString::fromUtf8(file.readAll()).trimmed();
        file.close();
        if (!newIp.isEmpty()) {
            hasTarget = true;
        }
    }

    if (newIp != m_targetIp || hasTarget != m_hasTarget) {
        m_targetIp = newIp;
        m_hasTarget = hasTarget;
        emit targetIpChanged();
    }
}

void CyberBackend::setTarget(const QString &ip) {
    const QString cleanIp = ip.trimmed();
    if (cleanIp.isEmpty() || cleanIp.toLower() == QLatin1String("clear") || cleanIp.toLower() == QLatin1String("reset")) {
        clearTarget();
        return;
    }

    QFile file(m_targetFilePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        file.write(cleanIp.toUtf8());
        file.close();
        reloadTargetIp();
        emit feedbackMessage(QStringLiteral("Target Updated"), QStringLiteral("Active target set to %1").arg(cleanIp));
    }
}

void CyberBackend::clearTarget() {
    QFile::remove(m_targetFilePath);
    reloadTargetIp();
    emit feedbackMessage(QStringLiteral("Target Cleared"), QStringLiteral("Active target has been reset."));
}

void CyberBackend::setupVpnMonitor() {
    m_vpnPollTimer.setInterval(2000);
    connect(&m_vpnPollTimer, &QTimer::timeout, this, &CyberBackend::updateVpnStatus);
    m_vpnPollTimer.start();
}

void CyberBackend::updateVpnStatus() {
    QString foundIp;
    QString foundIface;
    bool foundConnected = false;

    const QList<QNetworkInterface> interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface &iface : interfaces) {
        if (!(iface.flags() & QNetworkInterface::IsUp) || !(iface.flags() & QNetworkInterface::IsRunning)) {
            continue;
        }

        const QString name = iface.name();
        const bool isVpnName = name.startsWith(QLatin1String("tun"))
                            || name.startsWith(QLatin1String("wg"))
                            || name.startsWith(QLatin1String("tailscale"))
                            || name.startsWith(QLatin1String("tap"))
                            || name.startsWith(QLatin1String("ppp"));

        if (!isVpnName) {
            continue;
        }

        const QList<QNetworkAddressEntry> entries = iface.addressEntries();
        for (const QNetworkAddressEntry &entry : entries) {
            const QHostAddress ip = entry.ip();
            if (ip.protocol() == QAbstractSocket::IPv4Protocol && !ip.isLoopback()) {
                foundIp = ip.toString();
                foundIface = name;
                foundConnected = true;
                break;
            }
        }

        if (foundConnected) {
            break;
        }
    }

    if (foundConnected != m_vpnConnected || foundIp != m_vpnIp || foundIface != m_vpnInterface) {
        m_vpnConnected = foundConnected;
        m_vpnIp = foundIp;
        m_vpnInterface = foundIface;
        emit vpnStateChanged();
    }
}

void CyberBackend::copyToClipboard(const QString &text) {
    if (text.isEmpty()) return;
    QProcess process;
    process.setProgram(QStringLiteral("wl-copy"));
    process.setArguments(QStringList() << text);
    process.start();
    process.waitForFinished(1000);
}

void CyberBackend::copyTarget() {
    if (m_hasTarget && !m_targetIp.isEmpty()) {
        copyToClipboard(m_targetIp);
        emit feedbackMessage(QStringLiteral("Target Copied"), QStringLiteral("%1 copied to clipboard").arg(m_targetIp));
    }
}

void CyberBackend::copyVpn() {
    if (m_vpnConnected && !m_vpnIp.isEmpty()) {
        copyToClipboard(m_vpnIp);
        emit feedbackMessage(QStringLiteral("VPN IP Copied"), QStringLiteral("%1 copied to clipboard").arg(m_vpnIp));
    }
}

void CyberBackend::launchTerminalCommand(const QString &command, const QString &title) {
    if (command.trimmed().isEmpty()) return;

    QString terminal = QStringLiteral("kitty");
    QStringList args;

    if (!title.isEmpty()) {
        args << QStringLiteral("--title") << title;
    }

    args << QStringLiteral("bash") << QStringLiteral("-c")
         << QStringLiteral("%1; echo ''; echo '[Press Enter to close]'; read line").arg(command);

    QProcess::startDetached(terminal, args);
}

void CyberBackend::launchGuiTool(const QString &command) {
    if (command.trimmed().isEmpty()) return;
    QProcess::startDetached(command, QStringList());
    emit feedbackMessage(QStringLiteral("Tool Launched"), QStringLiteral("Started %1").arg(command));
}

void CyberBackend::runQuickNmap(const QString &scanType) {
    if (!m_hasTarget || m_targetIp.isEmpty()) {
        emit feedbackMessage(QStringLiteral("No Target Set"), QStringLiteral("Please set a Target IP before running Nmap scans."));
        return;
    }

    QString cmd;
    QString title;

    if (scanType == QLatin1String("fast")) {
        title = QStringLiteral("Nmap Fast Scan - %1").arg(m_targetIp);
        cmd = QStringLiteral("nmap -F -sV %1").arg(m_targetIp);
    } else if (scanType == QLatin1String("full")) {
        title = QStringLiteral("Nmap Full Port Scan - %1").arg(m_targetIp);
        cmd = QStringLiteral("nmap -p- --min-rate 1000 -T4 -sV %1").arg(m_targetIp);
    } else if (scanType == QLatin1String("vuln")) {
        title = QStringLiteral("Nmap Vulnerability Scan - %1").arg(m_targetIp);
        cmd = QStringLiteral("nmap -sV --script vuln %1").arg(m_targetIp);
    } else if (scanType == QLatin1String("udp")) {
        title = QStringLiteral("Nmap Top UDP Scan - %1").arg(m_targetIp);
        cmd = QStringLiteral("sudo nmap -sU --top-ports 20 %1").arg(m_targetIp);
    } else {
        title = QStringLiteral("Nmap Standard Scan - %1").arg(m_targetIp);
        cmd = QStringLiteral("nmap -sC -sV %1").arg(m_targetIp);
    }

    launchTerminalCommand(cmd, title);
    emit feedbackMessage(QStringLiteral("Scan Initiated"), QStringLiteral("Running %1 in terminal").arg(title));
}
