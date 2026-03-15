import Gtk from "gi://Gtk"
import { Astal } from "ags/gtk4"

//import Clock from ".bar/Clock"
import Workspaces from ".bar/Workspace"
//import Battery from ".bar/Battery"
//import Media from ".bar/Media"
//import Network from ".bar/Network"

function Seperator() {
  return <label label="." cssClasses={["seperator"]} />
}

export default function Bar() {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      anchor={TOP | LEFT | RIGHT}
      layer={Astal.Layer.TOP}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <box cssClasses={["modules-left"]}>
            <Clock format="%-I:%M" />
            </box>
          <box cssClasses={["modules-center"]}>
            <Media />
            <Seperator />
            <Workspaces />
          </box>
          <box cssClasses={["modules-right"]}>
            <Network />
            <Battery />
            </box> 
      </box>
     </window>
  );
}
