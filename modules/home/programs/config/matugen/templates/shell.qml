import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }

  height: 30
  color: "{{colors.background.default.hex}}"

  RowLayout {
    anchors.fill: parent
    anchors.margins: 5
    spacing: 10

    // Left modules
    RowLayout {
      Layout.alignment: Qt.AlignLeft
      spacing: 10

      // Custom NixOS
      Text {
        text: ""
        color: "{{colors.primary.default.hex}}"
        font.pixelSize: 20
        font.family: "JetBrainsMono Nerd Font"
      }

      // Hyprland Workspaces
      Repeater {
        model: Hyprland.workspaces

        Rectangle {
          width: 30
          height: 20
          color: modelData.active ? "{{colors.primary.default.hex}}" : "{{colors.surface_container.default.hex}}"
          radius: 4

          Text {
            anchors.centerIn: parent
            text: modelData.name
            color: modelData.active ? "{{colors.on_primary.default.hex}}" : "{{colors.on_surface.default.hex}}"
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
          }
        }
      }

      // Cava placeholder - audio visualizer
      Row {
        spacing: 1
        Repeater {
          model: 14
          Rectangle {
            width: 3
            height: Math.random() * 20 + 5
            color: "{{colors.primary.default.hex}}"
            radius: 1
          }
        }
      }
    }

    // Center module
    Text {
      Layout.alignment: Qt.AlignCenter
      text: Hyprland.activeWindow?.title || ""
      color: "{{colors.on_surface.default.hex}}"
      font.pixelSize: 14
      font.family: "JetBrainsMono Nerd Font"
      elide: Text.ElideMiddle
      maximumLineCount: 1
    }

    // Right modules
    RowLayout {
      Layout.alignment: Qt.AlignRight
      spacing: 10

      // System Tray
      Repeater {
        model: SystemTray.items

        IconImage {
          source: modelData.iconName
          width: 16
          height: 16
        }
      }

      // Network
      Text {
        text: {
          var proc = Process {
            command: ["nmcli", "-t", "-f", "STATE", "general"]
            running: true
            stdout: StdioCollector {
              onStreamFinished: text = this.text.trim() === "connected" ? "" : ""
            }
          }
          return ""
        }
        color: "{{colors.on_surface.default.hex}}"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
      }

      // PulseAudio
      Text {
        text: " " + Math.round(Pipewire.defaultAudioSink?.volume * 100) + "%"
        color: "{{colors.on_surface.default.hex}}"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
      }

      // Clock
      Text {
        text: Qt.formatDateTime(SystemClock.date, "ddd MMM d hh:mm")
        color: "{{colors.on_surface.default.hex}}"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
      }

      // Battery
      Text {
        text: {
          var bat = UPower.devices.find(d => d.type === UPowerDeviceType.Battery)
          return bat ? Math.round(bat.percentage) + "% " + (bat.charging ? "󰂄" : "󰁹") : ""
        }
        color: "{{colors.on_surface.default.hex}}"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
      }
    }
  }
}