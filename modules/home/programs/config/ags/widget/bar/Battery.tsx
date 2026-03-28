import AstalBattery from "gi://AstalBattery"
import Gtk from "gi://Gtk"
import { createBinding } from "ags"

export default function Battery() {
  const battery = AstalBattery.get_default()

  const batteryStyle = createBinding(battery, "percentage").as((p) => {
    const percent = Math.round(p * 100)
    const fillColor = p > 0.3 ? "@accent_color" : "@error"
    const trackColor = "@headerbar_bg_color"

    return `background: linear-gradient(
      to right,
      ${fillColor} 0%,
      ${fillColor} ${percent}%,
      ${trackColor} ${percent}%,
      ${trackColor} 100%
    );`
  })

  const labelClass = createBinding(battery, "percentage").as((p) =>
    p > 0.4 ? ["battery-label", "dark"] : ["battery-label", "light"]
  )

  return (
    <box
      visible={createBinding(battery, "isPresent")}
      cssClasses={["battery-pill"]}
      css={batteryStyle}
      valign={Gtk.Align.CENTER}
    >
      <label
        hexpand
        vexpand
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        cssClasses={labelClass}
        label={createBinding(battery, "percentage").as(
          (p) => `${Math.round(p * 100)}%`
        )}
      />
    </box>
  )
}