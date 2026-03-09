import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createBinding, createState, createMemo } from "gnim/jsx/state"
import { createPoll } from "ags/time"
import Battery from "gi://AstalBattery"
import Wp from "gi://AstalWp"
import Network from "gi://AstalNetwork"
import Mpris from "gi://AstalMpris"
import Hyprland from "gi://AstalHyprland"

// ── LEFT ──────────────────────────────────────────────────

function Launcher() {
  return (
    <button
      cssName="launcher"
      onClicked={() =>
        execAsync("pkill rofi || rofi -show drun -theme ~/.config/rofi/themes/grid.rasi")
      }
    >
      <label label="" />
    </button>
  )
}

function Clock() {
  const time = createPoll("", 1000, "date +'%I:%M %p'")
  return <label cssName="clock" label={time} />
}

function Workspaces() {
  const hypr = Hyprland.get_default()
  const workspaces = createBinding(hypr, "workspaces")
  const focused = createBinding(hypr, "focusedWorkspace")

  return (
    <box cssName="workspaces">
      {() => workspaces()
        .filter(ws => ws.id > 0)
        .sort((a, b) => a.id - b.id)
        .map(ws => (
          <button
            cssName={focused()?.id === ws.id ? "workspace-btn active" : "workspace-btn"}
            onClicked={() => hypr.dispatch("workspace", String(ws.id))}
          >
            <label label={String(ws.id)} />
          </button>
        ))
      }
    </box>
  )
}

// ── CENTER ────────────────────────────────────────────────

function Media() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box cssName="media">
      {() => {
        const player = players()[0]
        if (!player) return <label label="" />

        const status = createBinding(player, "playbackStatus")
        const title = createBinding(player, "title")

        const icon = status() === Mpris.PlaybackStatus.PLAYING ? "  " : "  "
        const t = title()
        const artist = player.artist
        const text = t ? (artist ? `${artist} - ${t}` : t) : ""

        return (
          <button onClicked={() => player.play_pause()}>
            <box spacing={6}>
              <label label={icon} />
              <label label={text} maxWidthChars={40} ellipsize={3} />
            </box>
          </button>
        )
      }}
    </box>
  )
}

// ── RIGHT ─────────────────────────────────────────────────

function Volume() {
  const audio = Wp.get_default()?.audio
  if (!audio) return <box />

  const speaker = createBinding(audio, "defaultSpeaker")

  return (
    <button cssName="volume" onClicked={() => execAsync("pwvucontrol")}>
      <label label={() => {
        const spk = speaker()
        if (!spk) return "󰕾"
        const vol = Math.round(spk.volume * 100)
        if (spk.mute)  return `Muted 󰖁`
        if (vol < 30)  return `${vol}% 󰕿`
        if (vol < 60)  return `${vol}% 󰖀`
        return `${vol}% 󰕾`
      }} />
    </button>
  )
}

function BatteryWidget() {
  const bat = Battery.get_default()
  const icons = ["", "", "", "", ""]
  const pct = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")

  return (
    <box cssName="battery">
      <label
        label={() => {
          const p = Math.round(pct() * 100)
          const icon = icons[Math.min(Math.floor(p / 20), 4)]
          const prefix = charging() ? "⚡" : ""
          return `${prefix}${p}% ${icon}`
        }}
      />
    </box>
  )
}

function NetworkWidget() {
  const network = Network.get_default()
  const wifi = createBinding(network, "wifi")

  return (
    <label
      cssName="network"
      label={() => {
        const w = wifi()
        return w?.ssid ? `${w.ssid} ` : " "
      }}
    />
  )
}

function NotificationBell() {
  return (
    <button
      cssName="notification"
      onClicked={() => execAsync("swaync-client -t -sw")}
    >
      <label label="" />
    </button>
  )
}

// ── BAR ───────────────────────────────────────────────────

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      cssName="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox>
        <box $type="start" spacing={10} cssName="bar-left">
          <Launcher />
          <Clock />
          <Workspaces />
        </box>
        <box $type="center" cssName="bar-center">
          <Media />
        </box>
        <box $type="end" halign={Gtk.Align.END} spacing={10} cssName="bar-right">
          <Volume />
          <BatteryWidget />
          <NetworkWidget />
          <NotificationBell />
        </box>
      </centerbox>
    </window>
  )
}