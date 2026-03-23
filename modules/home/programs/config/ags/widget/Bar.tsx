import { Astal, Gtk } from "ags/gtk4"

import Clock from "./bar/Clock"
import Media from "./bar/Media"
import Workspaces from "./bar/Workspaces"
import Wireless from "./bar/Wireless"
import Battery from "./bar/Battery"

export default function Bar() {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      namespace="my-ags-bar"
      anchor={TOP | LEFT | RIGHT}
      layer={Astal.Layer.TOP}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <box cssClasses={["left-modules"]}>
          <Clock format="%-I:%M" />
        </box>
        <box cssClasses={["center-modules"]}>
          <Media />
          <Workspaces />
        </box>
        <box cssClasses={["right-modules"]}>
          <Wireless />
          <Battery />
        </box>
      </box>
    </window>
  )
}
