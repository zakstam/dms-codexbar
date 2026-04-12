import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "codexBar"

    StyledRect {
        width: parent.width
        radius: Theme.cornerRadius + 4
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.withAlpha(Theme.primary, 0.2)
        implicitHeight: heroColumn.implicitHeight + Theme.spacingL * 2
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.withAlpha(Theme.primary, 0.16) }
                GradientStop { position: 0.56; color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.08) }
                GradientStop { position: 1.0; color: Theme.withAlpha(Theme.surfaceContainer, 0.02) }
            }
        }

        Rectangle {
            width: 160
            height: 160
            radius: 80
            x: parent.width - width * 0.72
            y: -height * 0.35
            color: Theme.withAlpha(Theme.primary, 0.08)
        }

        Column {
            id: heroColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingS

            StyledText {
                width: parent.width
                text: "Premium usage telemetry"
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Font.DemiBold
            }

            StyledText {
                width: parent.width
                text: "CodexBar Settings"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }

            StyledText {
                width: parent.width
                text: "Configure how CodexBar is executed, how often telemetry refreshes, and which source mode powers your DankBar widget."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }

    StyledText {
        width: parent.width
        text: "Runtime"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    DankDropdown {
        id: refreshDropdown
        text: "Refresh Interval"
        description: "How often usage telemetry is fetched from CodexBar."
        currentValue: root.loadValue("refreshInterval", "120000")
        options: [
            "60000",
            "120000",
            "300000",
            "900000",
            "1800000"
        ]
        dropdownWidth: 180
        onValueChanged: function(value) {
            root.saveValue("refreshInterval", value);
        }
    }

    StyledText {
        width: parent.width
        leftPadding: Theme.spacingM
        text: {
            const value = refreshDropdown.currentValue;
            if (value === "60000") return "Refreshes every 1 minute";
            if (value === "120000") return "Refreshes every 2 minutes";
            if (value === "300000") return "Refreshes every 5 minutes";
            if (value === "900000") return "Refreshes every 15 minutes";
            if (value === "1800000") return "Refreshes every 30 minutes";
            return "";
        }
        font.pixelSize: Theme.fontSizeSmall
        font.italic: true
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "Binary"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingXS

        StyledText {
            width: parent.width
            text: "Path to the codexbar executable. Leave empty to auto-detect PATH, ~/.local/bin, and /usr/local/bin."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        DankTextField {
            width: parent.width
            text: root.loadValue("codexbarPath", "")
            placeholderText: "/home/user/.local/bin/codexbar"
            onEditingFinished: root.saveValue("codexbarPath", text)
        }
    }

    StyledText {
        width: parent.width
        text: "Source mode"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    DankDropdown {
        id: sourceDropdown
        text: "Source Mode"
        description: "OAuth is the safest default. API mode requires provider API tokens."
        currentValue: root.loadValue("sourceMode", "oauth")
        options: [
            "oauth",
            "cli",
            "api"
        ]
        dropdownWidth: 180
        onValueChanged: function(value) {
            root.saveValue("sourceMode", value);
        }
    }

    StyledText {
        width: parent.width
        leftPadding: Theme.spacingM
        text: {
            const value = sourceDropdown.currentValue;
            if (value === "oauth") return "OAuth: Uses signed-in provider tokens (recommended)";
            if (value === "cli") return "CLI: Reads usage via PTY probe (may timeout on some providers)";
            if (value === "api") return "API: Uses provider API tokens; ChatGPT Plus alone is not enough";
            return "";
        }
        font.pixelSize: Theme.fontSizeSmall
        font.italic: true
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.warning, 0.1)
        border.width: 1
        border.color: Theme.withAlpha(Theme.warning, 0.26)
        implicitHeight: cautionText.implicitHeight + Theme.spacingM * 2

        StyledText {
            id: cautionText
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            text: "If you only have ChatGPT Plus, keep Source Mode on OAuth or CLI."
            color: Theme.warning
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }
    }

    StyledText {
        width: parent.width
        text: "Quick setup"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    StyledRect {
        width: parent.width
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.withAlpha(Theme.surfaceText, 0.08)
        implicitHeight: checklistColumn.implicitHeight + Theme.spacingM * 2

        Column {
            id: checklistColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingXS

            Repeater {
                model: [
                    "1. Install CodexBar CLI (official Linux build)",
                    "2. Test: codexbar usage --format json --provider codex --source oauth",
                    "3. Keep this plugin enabled in DankBar widgets"
                ]

                StyledText {
                    required property string modelData
                    width: parent.width
                    text: modelData
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
