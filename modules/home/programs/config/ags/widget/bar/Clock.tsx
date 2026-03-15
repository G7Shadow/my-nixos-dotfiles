import GLib from "gi://GLib"
import Gtk from "gi://Gtk"
import { createPoll } from "ags/time"

export default function Clock({ format = "%H:%M" }) {
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format(format) ?? "??"
  )

  const calendar = new Gtk.Calendar()
  const popover = <popover child={calendar as any} /> as Gtk.Popover

  return (
    <menubutton cssClasses={["clock"]} popover={popover as any}>
      <label label={time} />
    </menubutton>
  )
}