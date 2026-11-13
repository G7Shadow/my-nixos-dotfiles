pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import "../config"

// Aggregate system battery (UPower's display device), reactive. `available` is false on
// desktops or anywhere there's no laptop battery, so the bar knows to hide the indicator.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: device ? device.isLaptopBattery : false
    // Quickshell hands you percentage on a 0..1 scale (checked it: 0.80 == 80%), so times 100.
    readonly property int percentage: device ? Math.round(device.percentage * 100) : 0
    // Use the real charge-state enum. "On AC" (!onBattery) is NOT the same as actually
    // charging: a plugged-in laptop holding at 80% reports PendingCharge, not Charging.
    readonly property bool charging: device ? device.state === UPowerDeviceState.Charging : false
    readonly property bool discharging: device ? device.state === UPowerDeviceState.Discharging : false
    readonly property bool low: available && discharging && percentage <= Config.batteryLowThreshold

    // What there is to say beside the number: how long it will last, how long until it
    // is full, or simply that it is plugged in. UPower's estimates are 0 while it has
    // none (the first moments after plugging or unplugging), and then the plain state
    // is said instead of "0 min".
    readonly property bool full: device ? device.state === UPowerDeviceState.FullyCharged : false
    readonly property real secondsLeft: device ? device.timeToEmpty : 0
    readonly property real secondsToFull: device ? device.timeToFull : 0
    // "45 min", "3 h", "2 h 40 min"
    function span(s) {
        const m = Math.max(1, Math.round(s / 60));
        if (m < 60) return m + " min";
        const h = Math.floor(m / 60), r = m % 60;
        return r === 0 ? h + " h" : h + " h " + r + " min";
    }
    readonly property string detail: !available ? ""
        : charging ? (secondsToFull > 0 ? span(secondsToFull) + " to full" : "Charging")
        : discharging ? (secondsLeft > 0 ? span(secondsLeft) + " left" : "On battery")
        : full ? "Full" : "Plugged in"
}
