import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
  id: root

  // === State ===
  property var providers: []
  property bool isLoading: false
  property bool hasError: false
  property string errorMessage: ""
  property string lastUpdated: ""
  property string rawJsonBuffer: ""
  property bool binaryReady: false

  // === Settings ===
  property int refreshIntervalMs: {
    var val = pluginData.refreshInterval
    return val ? parseInt(val) : 120000
  }
  property string codexbarPath: pluginData.codexbarPath || ""
  property string sourceMode: pluginData.sourceMode || "oauth"

  // === Derived: highest-usage provider for the bar pill ===
  readonly property var highestProvider: {
    if (providers.length === 0) return null
    var filtered = providers.filter(function(p) {
      return p.usage && p.usage.primary && !p.error
    })
    if (filtered.length === 0) return null
    var highest = filtered[0]
    for (var i = 1; i < filtered.length; i++) {
      if (filtered[i].usage.primary.usedPercent > highest.usage.primary.usedPercent)
        highest = filtered[i]
    }
    return highest
  }

  readonly property real highestPercent: {
    if (!highestProvider || !highestProvider.usage || !highestProvider.usage.primary) return 0
    return highestProvider.usage.primary.usedPercent
  }

  readonly property string highestName: {
    if (!highestProvider) return "N/A"
    return capitalizeFirst(highestProvider.provider)
  }

  // === Helpers ===
  function getUsageColor(pct) {
    if (pct >= 80) return Theme.error
    if (pct >= 60) return Theme.warning
    return Theme.success
  }

  function capitalizeFirst(s) {
    if (!s) return ""
    return s.charAt(0).toUpperCase() + s.slice(1)
  }

  function formatTimeUntil(iso) {
    if (!iso) return ""
    var diff = new Date(iso).getTime() - Date.now()
    if (diff <= 0) return "now"
    var mins = Math.floor(diff / 60000)
    if (mins < 60) return mins + "m"
    var hrs = Math.floor(mins / 60)
    if (hrs < 24) return hrs + "h " + (mins % 60) + "m"
    var days = Math.floor(hrs / 24)
    return days + "d " + (hrs % 24) + "h"
  }

  function getWindowLabel(windowMinutes) {
    if (!windowMinutes) return ""
    if (windowMinutes <= 300) return "Session"
    if (windowMinutes <= 10080) return "Weekly"
    return Math.floor(windowMinutes / 1440) + "d"
  }

  readonly property string resolvedPath: codexbarPath && codexbarPath.length > 0 ? codexbarPath : "codexbar"

  // === Binary detection ===
  Component.onCompleted: {
    // Skip detection if user set a path in settings
    if (root.codexbarPath) {
      root.binaryReady = true
      root.refresh()
    } else {
      procDetect.running = true
    }
  }

  Process {
    id: procDetect
    command: ["sh", "-c", "which codexbar 2>/dev/null || (test -x $HOME/.local/bin/codexbar && echo $HOME/.local/bin/codexbar) || (test -x /usr/local/bin/codexbar && echo /usr/local/bin/codexbar) || echo ''"]
    stdout: SplitParser {
      onRead: line => {
        var trimmed = line.trim()
        if (trimmed.length > 0 && !root.codexbarPath)
          root.codexbarPath = trimmed
      }
    }
    onExited: code => {
      if (root.codexbarPath) {
        root.binaryReady = true
        root.refresh()
      } else {
        root.hasError = true
        root.errorMessage = "codexbar not found. Set path in settings."
      }
    }
  }

  // === Usage fetch ===
  Process {
    id: procUsage
    command: {
      var cmd = [root.resolvedPath, "usage", "--format", "json", "--provider", "both"]
      if (root.sourceMode && root.sourceMode !== "auto") {
        cmd.push("--source")
        cmd.push(root.sourceMode)
      }
      return cmd
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { root.rawJsonBuffer += data }
    }
    stderr: SplitParser {
      onRead: line => console.warn("CodexBar stderr:", line)
    }
    onExited: code => {
      root.isLoading = false
      if (code === 0 && root.rawJsonBuffer.length > 0) {
        try {
          var data = JSON.parse(root.rawJsonBuffer)
          if (!Array.isArray(data)) data = [data]
          root.providers = data
          root.hasError = false
          root.errorMessage = ""
          root.lastUpdated = Qt.formatDateTime(new Date(), "hh:mm:ss")
        } catch (e) {
          console.warn("CodexBar: JSON parse error:", e)
          root.hasError = true
          root.errorMessage = "Failed to parse CLI output"
        }
      } else if (code !== 0) {
        root.hasError = true
        root.errorMessage = "codexbar exited with code " + code
      }
      root.rawJsonBuffer = ""
    }
  }

  function refresh() {
    if (procUsage.running) return
    root.isLoading = true
    root.rawJsonBuffer = ""
    procUsage.running = true
  }

  Timer {
    interval: root.refreshIntervalMs
    running: root.binaryReady
    repeat: true
    onTriggered: root.refresh()
  }

  // === Bar pill (horizontal) ===
  horizontalBarPill: Component {
    Row {
      spacing: Theme.spacingXS

      DankIcon {
        name: "monitoring"
        size: Theme.iconSize - 6
        color: root.getUsageColor(root.highestPercent)
        anchors.verticalCenter: parent.verticalCenter
      }

      StyledText {
        text: {
          if (root.hasError && root.providers.length === 0) return "ERR"
          if (root.isLoading && root.providers.length === 0) return "..."
          if (!root.highestProvider) return "N/A"
          return root.highestName + " " + Math.round(root.highestPercent) + "%"
        }
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: root.getUsageColor(root.highestPercent)
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // === Bar pill (vertical) ===
  verticalBarPill: Component {
    Column {
      spacing: Theme.spacingXS

      DankIcon {
        name: "monitoring"
        size: Theme.iconSize - 6
        color: root.getUsageColor(root.highestPercent)
        anchors.horizontalCenter: parent.horizontalCenter
      }

      StyledText {
        text: {
          if (!root.highestProvider) return "--"
          return Math.round(root.highestPercent) + "%"
        }
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: root.getUsageColor(root.highestPercent)
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  // === Popout ===
  popoutWidth: 420
  popoutHeight: 0

  popoutContent: Component {
    PopoutComponent {
      id: popup
      headerText: "AI Usage"
      detailsText: root.lastUpdated ? ("Updated " + root.lastUpdated) : ""
      showCloseButton: true

      headerActions: Component {
        Row {
          spacing: Theme.spacingXS

          Rectangle {
            width: 28; height: 28; radius: 14
            color: refreshArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

            DankIcon {
              anchors.centerIn: parent
              name: "refresh"
              size: 16
              color: Theme.surfaceText
            }

            MouseArea {
              id: refreshArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.refresh()
            }
          }
        }
      }

      Item {
        id: contentWrapper
        width: parent.width
        implicitHeight: mainCol.implicitHeight

        Column {
          id: mainCol
          width: parent.width
          spacing: Theme.spacingS

          // Error banner
          StyledRect {
            width: parent.width
            height: errCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
            visible: root.hasError && root.providers.length === 0

            Column {
              id: errCol
              anchors.fill: parent
              anchors.margins: Theme.spacingM
              spacing: Theme.spacingXS

              Row {
                spacing: Theme.spacingS
                DankIcon {
                  name: "error"
                  size: 18
                  color: Theme.error
                  anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                  text: root.errorMessage
                  font.pixelSize: Theme.fontSizeMedium
                  color: Theme.error
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }

          // Loading
          StyledText {
            visible: root.isLoading && root.providers.length === 0
            text: "Fetching usage data..."
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
          }

          // Provider cards
          Repeater {
            model: root.providers

            StyledRect {
              required property var modelData
              required property int index

              width: mainCol.width
              height: providerCol.implicitHeight + Theme.spacingM * 2
              radius: Theme.cornerRadius
              color: Theme.surfaceContainerHigh

              Column {
                id: providerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                // Provider name + login
                Row {
                  spacing: Theme.spacingS

                  StyledText {
                    text: root.capitalizeFirst(modelData.provider)
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                  }

                  StyledText {
                    text: {
                      if (modelData.usage && modelData.usage.identity && modelData.usage.identity.loginMethod)
                        return modelData.usage.identity.loginMethod
                      return ""
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text.length > 0
                  }
                }

                // Error state for this provider
                Row {
                  visible: !!modelData.error
                  spacing: Theme.spacingXS

                  DankIcon {
                    name: "warning"
                    size: 14
                    color: Theme.error
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  StyledText {
                    text: modelData.error ? (modelData.error.message || "Error") : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                // Primary (session) window
                Column {
                  width: parent.width
                  spacing: 2
                  visible: !!modelData.usage && !!modelData.usage.primary

                  Item {
                    width: parent.width
                    height: Math.max(primLabel.implicitHeight, primValue.implicitHeight)

                    StyledText {
                      id: primLabel
                      anchors.left: parent.left
                      text: root.getWindowLabel(modelData.usage && modelData.usage.primary ? modelData.usage.primary.windowMinutes : null)
                      font.pixelSize: Theme.fontSizeSmall
                      color: Theme.surfaceVariantText
                    }
                    StyledText {
                      id: primValue
                      anchors.right: parent.right
                      text: {
                        if (!modelData.usage || !modelData.usage.primary) return ""
                        var pct = Math.round(modelData.usage.primary.usedPercent)
                        var reset = root.formatTimeUntil(modelData.usage.primary.resetsAt)
                        return pct + "%" + (reset ? " \u00B7 " + reset : "")
                      }
                      font.pixelSize: Theme.fontSizeSmall
                      color: root.getUsageColor(modelData.usage && modelData.usage.primary ? modelData.usage.primary.usedPercent : 0)
                    }
                  }

                  Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Theme.surfaceContainerHighest

                    Rectangle {
                      width: {
                        var pct = modelData.usage && modelData.usage.primary ? modelData.usage.primary.usedPercent : 0
                        return Math.min(1, pct / 100) * parent.width
                      }
                      height: parent.height; radius: parent.radius
                      color: root.getUsageColor(modelData.usage && modelData.usage.primary ? modelData.usage.primary.usedPercent : 0)
                      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                  }
                }

                // Secondary (weekly) window
                Column {
                  width: parent.width
                  spacing: 2
                  visible: !!modelData.usage && !!modelData.usage.secondary

                  Item {
                    width: parent.width
                    height: Math.max(secLabel.implicitHeight, secValue.implicitHeight)

                    StyledText {
                      id: secLabel
                      anchors.left: parent.left
                      text: root.getWindowLabel(modelData.usage && modelData.usage.secondary ? modelData.usage.secondary.windowMinutes : null)
                      font.pixelSize: Theme.fontSizeSmall
                      color: Theme.surfaceVariantText
                    }
                    StyledText {
                      id: secValue
                      anchors.right: parent.right
                      text: {
                        if (!modelData.usage || !modelData.usage.secondary) return ""
                        var pct = Math.round(modelData.usage.secondary.usedPercent)
                        var reset = root.formatTimeUntil(modelData.usage.secondary.resetsAt)
                        return pct + "%" + (reset ? " \u00B7 " + reset : "")
                      }
                      font.pixelSize: Theme.fontSizeSmall
                      color: root.getUsageColor(modelData.usage && modelData.usage.secondary ? modelData.usage.secondary.usedPercent : 0)
                    }
                  }

                  Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Theme.surfaceContainerHighest

                    Rectangle {
                      width: {
                        var pct = modelData.usage && modelData.usage.secondary ? modelData.usage.secondary.usedPercent : 0
                        return Math.min(1, pct / 100) * parent.width
                      }
                      height: parent.height; radius: parent.radius
                      color: root.getUsageColor(modelData.usage && modelData.usage.secondary ? modelData.usage.secondary.usedPercent : 0)
                      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                  }
                }

                // Tertiary window
                Column {
                  width: parent.width
                  spacing: 2
                  visible: !!modelData.usage && !!modelData.usage.tertiary

                  Item {
                    width: parent.width
                    height: Math.max(terLabel.implicitHeight, terValue.implicitHeight)

                    StyledText {
                      id: terLabel
                      anchors.left: parent.left
                      text: {
                        if (!modelData.usage || !modelData.usage.tertiary) return ""
                        return modelData.usage.tertiary.resetDescription || "Tertiary"
                      }
                      font.pixelSize: Theme.fontSizeSmall
                      color: Theme.surfaceVariantText
                    }
                    StyledText {
                      id: terValue
                      anchors.right: parent.right
                      text: {
                        if (!modelData.usage || !modelData.usage.tertiary) return ""
                        var pct = Math.round(modelData.usage.tertiary.usedPercent)
                        var reset = root.formatTimeUntil(modelData.usage.tertiary.resetsAt)
                        return pct + "%" + (reset ? " \u00B7 " + reset : "")
                      }
                      font.pixelSize: Theme.fontSizeSmall
                      color: root.getUsageColor(modelData.usage && modelData.usage.tertiary ? modelData.usage.tertiary.usedPercent : 0)
                    }
                  }

                  Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Theme.surfaceContainerHighest

                    Rectangle {
                      width: {
                        var pct = modelData.usage && modelData.usage.tertiary ? modelData.usage.tertiary.usedPercent : 0
                        return Math.min(1, pct / 100) * parent.width
                      }
                      height: parent.height; radius: parent.radius
                      color: root.getUsageColor(modelData.usage && modelData.usage.tertiary ? modelData.usage.tertiary.usedPercent : 0)
                    }
                  }
                }

                // Credits
                Row {
                  visible: !!modelData.credits && modelData.credits.remaining > 0
                  spacing: Theme.spacingXS

                  DankIcon {
                    name: "toll"
                    size: 14
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  StyledText {
                    text: modelData.credits ? ("Credits: " + modelData.credits.remaining.toFixed(1)) : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                // Account email
                StyledText {
                  text: {
                    if (modelData.usage && modelData.usage.identity && modelData.usage.identity.accountEmail)
                      return modelData.usage.identity.accountEmail
                    return ""
                  }
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.surfaceVariantText
                  visible: text.length > 0
                }
              }
            }
          }

          // No providers
          StyledText {
            visible: root.providers.length === 0 && !root.hasError && !root.isLoading
            text: "No providers found. Check CodexBar CLI configuration."
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }
}
