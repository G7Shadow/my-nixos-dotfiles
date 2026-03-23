import AstalBattery from "gi://AstalBattery"
import { createBinding } from "ags"

export default function Battery() {
  const battery = AstalBattery.get_default()
  const isPresent = createBinding(battery, "isPresent")
  const percentage = createBinding(battery, "percentage")
  const charging = createBinding(battery, "charging")

  return (
    <box
      cssClasses={["battery"]}
      visible={isPresent}
    >
      <label
        label={percentage.as((p) => `${Math.round(p * 100)}%`)}
        cssClasses={charging.as((c) => c ? ["battery-label", "charging"] : ["battery-label"])}
      />
    </box>
  )
}