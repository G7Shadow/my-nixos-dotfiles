# Quickshell / Qt quirks I had to work around in this shell

Every single one of these is a real bug that actually cost me time, and there's code in the shell right now specifically defending against it. Line refs are to the files as they currently stand.

---

## 1. Qt's bezier spline solver just crashes on overshooting curves if you use too many segments

**Where:** `theme/Theme.qml` -> `springCurve()`

The motion system samples a damped harmonic oscillator step response and hands it off to Qt as a cubic bezier spline (`easing.bezierCurve`). I tried raising the segment count for better accuracy and it took the entire shell down lmao, not an exception, a full hard crash, once the segments got short enough in x on an overshooting (underdamped) curve.

- 12+ segments: crashes
- 10: last count that actually survived
- 8: the ceiling I ship with. Tracks the real spring within about 1% of travel, which is basically invisible anyway

```qml
// NOTE ON SEGMENT COUNT: Qt's bezier-spline solver CRASHES on an overshooting spline once
// the segments get too short in x (12+ segments took the whole shell down; 10 was the last
// that survived). 8 is the safe ceiling and still tracks the true spring to within ~1% of
// its travel, which is invisible. Do NOT raise it.
```

Also clamped `zeta` to `[0.4, 1.0]` so someone hand editing `config.json` can't divide by zero into a NaN curve and take the whole easing system down with it.

---

## 2. MultiEffect's drop shadow padding leaves a sliver of desktop showing above a flush surface

**Where:** `modules/bar/Bar.qml` -> `notchFill.over`

In notch mode the shape needs to sit truly flush against the top edge. It wasn't. There was a 1-2px line of desktop peeking above it, and it stuck around through theme changes so I knew it wasn't a color issue. Turned out the shadow layer's auto padding was insetting the painted shape inside its own layer.

Fix was just to overshoot the top edge and let the extra bit get clipped off screen.

```qml
readonly property real over: 4 * bar.notchT   // scales to 0 as it becomes the floating island
anchors.topMargin: -over
height: notch.height + over
```

The overshoot gets multiplied by `notchT` so it fades out as the notch morphs back into the floating island, since that needs its top gap back.

---

## 3. A Behavior chasing a target that changes every frame just stalls instead of animating

Honestly the most expensive lesson in this whole codebase. Got bit by this three separate times.

A `Behavior` restarts its tween every time the target property changes. So if the target itself is animating, the Behavior restarts every single frame toward a value that's only a hair ahead of where it started. The property basically crawls, looks frozen, then lurches to catch up once the driver finally settles.

**Case A, the clock slide.** Had `Behavior on x` where x depended on `clock.width`, which was layout animating. The clock sat centered for like a full second then just jumped to the right out of nowhere. Fix was to drive an animated progress value instead and make position a pure function of it:

```qml
property real expandT: (bar.expanded && !bar.barForm) ? 1 : 0
Behavior on expandT { NumberAnimation { ... } }
// x = center + t*(right - center); NO Behavior on x
x: (clock.width - width) * (1 + clock.expandT) / 2
```

**Case B, same clock but through width this time.** Wrapped the time text in an Item whose `width` tracked `timeText.scale`, which made `timeRow.width` change every frame, which set `clockBtn`'s `Behavior on width` (keyed off it) chasing again. Worth noting an item's width straight up ignores its scale transform in Qt, which is exactly why the un wrapped version worked in the first place, `timeRow.width` stayed constant so the width Behavior had one fixed target to chase.

**Case C, flushT / notchT.** Derived values that are already continuous should never get their own Behavior:

```qml
// continuous: closes to 0 as it goes flush (notch or game bar). No Behavior here —
// flushT is already animating, so one would just chase a per-frame target and stall.
anchors.topMargin: bar.topGap * (1 - bar.flushT)
```

Rule I stick to now: animate one single scalar clock and derive every dependent geometric value from it as a pure binding.

---

## 4. Corner radius stepping on a state change flashes sharp corners mid animation

**Where:** `modules/bar/Bar.qml` -> `notch.rad`

Radius was switched on a boolean (`expanded ? rIslandOpen : rIsland`) with its own Behavior attached. Hovering off snapped the radius toward the collapsed value the instant the state flipped, while the island was still at full height. Qt then clamps corners to `min(radius, height/2)`, which just made the mismatch worse, corners visibly went sharp for a beat until the shrink caught up. Fast hover on then off made it really obvious.

Fix was making radius a pure function of the live, already animated height, no second Behavior, so it literally can't desync from the size.

```qml
readonly property real rad: bar.barForm ? 0
      : Math.min(width / 2, height / 2,
            Theme.rIsland + (Theme.rIslandOpen - Theme.rIsland)
              * Math.max(0, Math.min(1, (height - bar.collapsedH)
                                        / Math.max(1, bar.expandedH - bar.collapsedH))))
```

Both the island Rectangle and the notch Shape read off this same value, so the two forms can never drift apart from each other.

---

## 5. Swapping two shapes with visible pops, one morphing outline doesn't

**Where:** `modules/bar/Bar.qml` -> `notchPath()` + `notchT`

Island to notch used to be a hard swap, a rounded Rectangle for a teardrop Shape, toggled via `visible`. One would pop out as the other popped in while the geometry animated underneath, and that popping is exactly what caused the chop. Now it's a single ShapePath covering both forms, interpolated by `notchT`.

Two smaller quirks fell out of fixing that:

- A zero radius SVG arc is just undefined behavior. Radii near zero have to degrade to straight lines, which is why there are `eps = 0.01` branches in `notchPath()`.
- The morph is two phase on purpose. An outline can't be a rounded top and a flared top at the same time, so `t < 0.5` un rounds the top corners and `t > 0.5` grows the flares:

```qml
readonly property real notchFlareEff: notchFlareRaw * Math.max(0, 2 * notchT - 1)
readonly property real notchTopR: notch.rad * Math.max(0, 1 - 2 * notchT)
```

- Radii need to be real, not int. They're interpolating continuously with height, and rounding to whole pixels re quantizes the corner into visible 1px stair steps mid animation.

---

## 6. Resizing a layer surface on open causes a morph flash

**Where:** `modules/bar/Bar.qml` -> `implicitHeight`

The bar window used to actually resize (116 to full height) whenever a panel opened. The layer surface reconfigure briefly yanked the island upward before it settled, a visible flash every time.

Fix was making the window always full height and fully transparent, with an input mask limiting what actually accepts clicks. Opening the launcher now never reconfigures the surface at all.

```qml
implicitHeight: modelData?.height ?? 1600
color: "transparent"
mask: Region { item: morphWanted ? backdrop : notch ... }
```

Stays anchored top/left/right (never bottom) so `exclusiveZone` still only reserves the strip it should.

---

## 7. WlrKeyboardFocus.OnDemand lets the pointer steal focus

**Where:** `modules/bar/Bar.qml`

Under focus follows mouse, `OnDemand` let the pointer just yank focus away from an open launcher or control center mid typing, super annoying. Switching to `Exclusive` while a panel is open fixes it:

```qml
WlrLayershell.keyboardFocus: morphWanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
```

---

## 8. A full screen overlay swallows every click unless the mask is literally empty

**Where:** `modules/screencorners/ScreenCorners.qml`

The rounded display corners are an Overlay layer surface covering the entire screen. Without an explicitly empty region it eats input for the whole desktop.

```qml
exclusionMode: ExclusionMode.Ignore
mask: Region {}          // empty = nothing accepts input; clicks fall through
visible: r > 0.5         // stay mapped through the whole animation
```

`visible: r > 0.5` matters here too, unmapping the surface the moment the radius starts shrinking would cut the retract animation off halfway. It only unmaps once the corners are actually gone.

---

## 9. Cold shader/FBO on first paint makes the lock entrance stutter while the exit is smooth

**Where:** `modules/lock/LockContent.qml`

Lock in hitched, unlock out didn't, even though it's the same animation with the same duration. The exit runs warm since every drop shadow layer FBO and the blur shader are already built by that point. The entrance runs cold.

Two things fix it:

1. A 90ms `enterDelay` timer lets the heavy first frame (snapshot decode plus blur FBO build) settle before the spring in even starts.
2. Elements idle at a hair above zero opacity instead of a hard 0, because Qt culls fully transparent items and just never builds their FBOs. Painting them invisibly during that beat warms everything up ahead of time.

```qml
blur: root.shown ? 1.0 : (LockState.unlocking ? 0.0 : 0.02)
```

The hidden value is 0.02 (visually sharp, basically unnoticeable) before unlock to keep the blur shader warm, but a true 0 on unlock so the final frame is pixel identical to the live desktop and nothing faintly blurred lingers before teardown.

---

## 10. grim: -o and -g are mutually exclusive

**Where:** `services/LockState.qml`

This is for capturing per monitor freeze frames for the lock background. You can't pass an output and a geometry at the same time, gotta pick one. I use `-o <output>` per screen, run them in parallel, then wait.

```qml
cmds.push("grim -t jpeg -q " + Config.lockShotQuality + " -o '" + s.name + "' '" + path + "'");
```

JPEG, not PNG, on purpose. PNG encoding measured around 850ms and was literally the entire reason the lock screen used to appear before its own background loaded lol.

There's a 700ms safety timer that engages the lock even if grim wedges or isn't installed. Fail closed, always.

---

## 11. PAM config: "login" was authenticating literally any password

**Where:** `services/LockState.qml`, security critical, not cosmetic, this one actually mattered.

```qml
config: "su"
```

`"login"` (pam_unix with try_first_pass nullok plus faillock) accepted an arbitrary password on this system. Not great lol. `"su"` (plain pam_unix) rejects it correctly like it should. Don't switch this back. `locked` only ever gets cleared in exactly one place, armed only by `PamResult.Success`.
