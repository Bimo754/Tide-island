pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import IslandBackend

FocusScope {
    id: root

    signal closeRequested

    property bool showCondition: false
    property string iconFontFamily: UserConfig.iconFontFamily
    property string textFontFamily: UserConfig.textFontFamily
    property string heroFontFamily: UserConfig.heroFontFamily

    readonly property string activeTarget: CyberBackend.targetIp
    readonly property bool hasTarget: CyberBackend.hasTarget
    readonly property string vpnIp: CyberBackend.vpnIp
    readonly property bool vpnConnected: CyberBackend.vpnConnected

    focus: showCondition
    activeFocusOnTab: true
    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 220 : 140
            easing.type: Easing.InOutQuad
        }
    }

    onShowConditionChanged: {
        if (showCondition) {
            targetInput.text = "";
            targetInput.forceActiveFocus();
        }
    }

    // Main Card Container
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 12
        radius: 18
        color: "transparent"

        Column {
            anchors.fill: parent
            spacing: 14

            // --- Header Row ---
            Item {
                width: parent.width
                height: 36

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅶"
                        color: "#ffffff"
                        font.pixelSize: 20
                        font.family: root.iconFontFamily
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Cyber Arsenal & Telemetry"
                        color: "#ffffff"
                        font.pixelSize: 17
                        font.bold: true
                        font.family: root.heroFontFamily
                    }
                }

                // Close Button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: 28
                    height: 28
                    radius: 14
                    color: closeArea.containsMouse ? "#26ffffff" : "#14ffffff"
                    border.width: 1
                    border.color: "#1fffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#ffffff"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // --- Telemetry & Target Controller Strip ---
            Row {
                width: parent.width
                height: 52
                spacing: 12

                // Target IP Status Pill
                Rectangle {
                    height: parent.height
                    width: 260
                    radius: 12
                    color: root.hasTarget ? "#260a84ff" : "#0dffffff"
                    border.width: 1
                    border.color: root.hasTarget ? "#660a84ff" : "#1affffff"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰓾"
                            color: root.hasTarget ? "#0a84ff" : "#73ffffff"
                            font.pixelSize: 16
                            font.family: root.iconFontFamily
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "TARGET IP"
                                color: "#73ffffff"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                            Text {
                                text: root.hasTarget ? root.activeTarget : "No Target Active"
                                color: root.hasTarget ? "#ffffff" : "#80ffffff"
                                font.pixelSize: 13
                                font.bold: root.hasTarget
                                font.family: root.textFontFamily
                            }
                        }
                    }

                    // Copy Button
                    Rectangle {
                        visible: root.hasTarget
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 58
                        height: 28
                        radius: 8
                        color: copyTargetArea.containsMouse ? "#0a84ff" : "#400a84ff"

                        Text {
                            anchors.centerIn: parent
                            text: "Copy"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: copyTargetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CyberBackend.copyTarget()
                        }
                    }
                }

                // Target Input Field & Submit
                Rectangle {
                    height: parent.height
                    width: 250
                    radius: 12
                    color: "#0dffffff"
                    border.width: 1
                    border.color: targetInput.activeFocus ? "#990a84ff" : "#1fffffff"

                    TextInput {
                        id: targetInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: setTargetBtn.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.family: root.textFontFamily
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !targetInput.text && !targetInput.activeFocus
                            text: "Set Target IP..."
                            color: "#59ffffff"
                            font.pixelSize: 12
                        }

                        onAccepted: {
                            if (targetInput.text.trim() !== "") {
                                CyberBackend.setTarget(targetInput.text.trim());
                                targetInput.text = "";
                            }
                        }
                    }

                    Rectangle {
                        id: setTargetBtn
                        anchors.right: clearTargetBtn.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 28
                        radius: 8
                        color: setTargetArea.containsMouse ? "#38ffffff" : "#1affffff"

                        Text {
                            anchors.centerIn: parent
                            text: "Set"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: setTargetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (targetInput.text.trim() !== "") {
                                    CyberBackend.setTarget(targetInput.text.trim());
                                    targetInput.text = "";
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: clearTargetBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 28
                        radius: 8
                        color: clearTargetArea.containsMouse ? "#4dff453a" : "#0fffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: clearTargetArea.containsMouse ? "#ff453a" : "#8cffffff"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: clearTargetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CyberBackend.clearTarget()
                        }
                    }
                }

                // VPN Status Pill
                Rectangle {
                    height: parent.height
                    width: 200
                    radius: 12
                    color: root.vpnConnected ? "#2630d158" : "#0dffffff"
                    border.width: 1
                    border.color: root.vpnConnected ? "#6630d158" : "#1affffff"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰖂"
                            color: root.vpnConnected ? "#30d158" : "#73ffffff"
                            font.pixelSize: 16
                            font.family: root.iconFontFamily
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "VPN STATUS"
                                color: "#73ffffff"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                            Text {
                                text: root.vpnConnected ? root.vpnIp : "Disconnected"
                                color: root.vpnConnected ? "#ffffff" : "#73ffffff"
                                font.pixelSize: 13
                                font.bold: root.vpnConnected
                                font.family: root.textFontFamily
                            }
                        }
                    }

                    // Copy VPN Button
                    Rectangle {
                        visible: root.vpnConnected
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 48
                        height: 28
                        radius: 8
                        color: copyVpnArea.containsMouse ? "#30d158" : "#4030d158"

                        Text {
                            anchors.centerIn: parent
                            text: "Copy"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: copyVpnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CyberBackend.copyVpn()
                        }
                    }
                }
            }

            // --- Section Title: Automated Scans ---
            Text {
                text: "AUTOMATED RECONNAISSANCE & SCANS"
                color: "#73ffffff"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.8
            }

            // Scan Action Cards Grid
            Row {
                width: parent.width
                spacing: 10

                // Fast Nmap
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 58
                    radius: 12
                    color: nmapFastArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#1affffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "⚡"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "Fast Port Scan"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                text: "nmap -F -sV"
                                color: "#73ffffff"
                                font.pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        id: nmapFastArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CyberBackend.runQuickNmap("fast")
                    }
                }

                // Full Port Nmap
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 58
                    radius: 12
                    color: nmapFullArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#1affffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "🔍"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "Full Port Scan"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                text: "nmap -p- --min-rate 1000"
                                color: "#73ffffff"
                                font.pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        id: nmapFullArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CyberBackend.runQuickNmap("full")
                    }
                }

                // Vuln Nmap
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 58
                    radius: 12
                    color: nmapVulnArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#1affffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "🛡️"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "Vulnerability Scan"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                text: "--script vuln"
                                color: "#73ffffff"
                                font.pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        id: nmapVulnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CyberBackend.runQuickNmap("vuln")
                    }
                }

                // Ping Target
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 58
                    radius: 12
                    color: pingArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#1affffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "📡"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "Ping Check"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                text: "ping -c 4 <target>"
                                color: "#73ffffff"
                                font.pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        id: pingArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.hasTarget) {
                                CyberBackend.launchTerminalCommand("ping -c 4 " + root.activeTarget, "Ping - " + root.activeTarget);
                            }
                        }
                    }
                }
            }

            // --- Section Title: Tool Launchers ---
            Text {
                text: "SECURITY SUITE LAUNCHERS"
                color: "#73ffffff"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.8
            }

            // Quick Tool Launchers
            Row {
                width: parent.width
                spacing: 10

                // Burp Suite
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 48
                    radius: 10
                    color: burpArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#14ffffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰱯"
                            color: "#ff9500"
                            font.pixelSize: 16
                            font.family: root.iconFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Burp Suite"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: burpArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CyberBackend.launchGuiTool("burpsuite")
                    }
                }

                // Wireshark
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 48
                    radius: 10
                    color: wireArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#14ffffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰈀"
                            color: "#0a84ff"
                            font.pixelSize: 16
                            font.family: root.iconFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Wireshark"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: wireArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CyberBackend.launchGuiTool("wireshark")
                    }
                }

                // Metasploit
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 48
                    radius: 10
                    color: msfArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#14ffffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰅵"
                            color: "#ff375f"
                            font.pixelSize: 16
                            font.family: root.iconFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Metasploit"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: msfArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CyberBackend.launchTerminalCommand("msfconsole", "Metasploit Framework")
                    }
                }

                // Web Directory Fuzzing
                Rectangle {
                    width: (parent.width - 30) / 4
                    height: 48
                    radius: 10
                    color: feroxArea.containsMouse ? "#1fffffff" : "#0dffffff"
                    border.width: 1
                    border.color: "#14ffffff"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "🌐"
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Web Directory"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: feroxArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.hasTarget) {
                                CyberBackend.launchTerminalCommand(
                                    "feroxbuster -u http://" + root.activeTarget + " || gobuster dir -u http://" + root.activeTarget + " -w /usr/share/wordlists/dirb/common.txt",
                                    "Web Recon - " + root.activeTarget
                                );
                            }
                        }
                    }
                }
            }
        }
    }
}
