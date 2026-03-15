import Glib from "gi://GLib";
import Gtk from "gi://Gtk";
import { createPoll } from 'ags/time';

export default function Clock({ format = "%H:%M" }) {
    const time = createPoll("",1000, () => {
        return Glib.DateTime.new_now_local().format(format) ?? "Invalid format"; 
    });
}
