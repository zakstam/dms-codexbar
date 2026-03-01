import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "codexBar"

    StyledText {
        width: parent.width
        text: "CodexBar"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Monitor AI provider usage quotas. Uses the CodexBar CLI to fetch session and weekly rate windows for Claude, Codex, Gemini, Copilot, and other providers."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Refresh Interval ---

    StyledText {
        width: parent.width
        text: "Refresh Interval"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    DankDropdown {
        id: refreshDropdown
        text: "Refresh Interval"
        description: "How often to fetch usage data from the CLI"
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
            root.saveValue("refreshInterval", value)
        }
    }

    StyledText {
        width: parent.width
        leftPadding: Theme.spacingM
        text: {
            var v = refreshDropdown.currentValue
            if (v === "60000") return "Refreshes every 1 minute"
            if (v === "120000") return "Refreshes every 2 minutes"
            if (v === "300000") return "Refreshes every 5 minutes"
            if (v === "900000") return "Refreshes every 15 minutes"
            if (v === "1800000") return "Refreshes every 30 minutes"
            return ""
        }
        font.pixelSize: Theme.fontSizeSmall
        font.italic: true
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Binary Path ---

    StyledText {
        width: parent.width
        text: "Binary Path"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: 5

        StyledText {
            width: parent.width
            text: "Path to the codexbar executable. Leave empty for auto-detection (searches PATH, ~/.local/bin, /usr/local/bin)."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        DankTextField {
            width: parent.width
            text: root.loadValue("codexbarPath", "")
            placeholderText: "/home/user/.local/bin/codexbar"
            onEditingFinished: {
                root.saveValue("codexbarPath", text)
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Source Mode ---

    StyledText {
        width: parent.width
        text: "Source Mode"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    DankDropdown {
        id: sourceDropdown
        text: "Source Mode"
        description: "How to fetch usage data. On Linux, 'cli' and 'api' are supported."
        currentValue: root.loadValue("sourceMode", "oauth")
        options: [
            "oauth",
            "cli",
            "api"
        ]
        dropdownWidth: 180
        onValueChanged: function(value) {
            root.saveValue("sourceMode", value)
        }
    }

    StyledText {
        width: parent.width
        leftPadding: Theme.spacingM
        text: {
            var v = sourceDropdown.currentValue
            if (v === "oauth") return "OAuth: Uses Claude/Codex OAuth tokens (recommended)"
            if (v === "cli") return "CLI: Reads usage via PTY probe (may timeout for Claude)"
            if (v === "api") return "API: Fetches usage via API tokens"
            return ""
        }
        font.pixelSize: Theme.fontSizeSmall
        font.italic: true
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Setup ---

    StyledText {
        width: parent.width
        text: "Setup"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingXS
        leftPadding: Theme.spacingM
        bottomPadding: Theme.spacingL

        Repeater {
            model: [
                "1. Install CodexBar CLI from GitHub Releases or via brew install steipete/tap/codexbar",
                "2. Test: codexbar usage --format json --source cli",
                "3. The plugin polls the CLI at the configured interval",
                "Note: On Linux, --source web is not supported. Use 'cli' or 'api'."
            ]

            StyledText {
                required property string modelData
                text: modelData
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                width: parent.width - Theme.spacingM
                wrapMode: Text.WordWrap
            }
        }
    }
}
