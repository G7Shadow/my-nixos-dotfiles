#!/usr/bin/env bash
# Switch VSCodium's colour theme for a theme-apply.sh scheme.
# Deputy to theme-apply.sh: reads <scheme>/vscodium-theme and patches
# ~/.config/VSCodium/User/settings.json IN PLACE (same inode, so an open
# VSCodium window's settings watcher fires and repaints live), leaving the
# rest of the file byte-for-byte untouched. Line-based, so JSONC trailing
# commas are fine; no jq needed.

name="${1:-}"
[ -n "$name" ] || exit 0

csdir="$HOME/.config/colorschemes/$name"
[ -f "$csdir/vscodium-theme" ] || exit 0
vsname="$(head -1 "$csdir/vscodium-theme")"
[ -n "$vsname" ] || exit 0

cfg="$HOME/.config/VSCodium/User/settings.json"
[ -f "$cfg" ] || exit 0

NEW_THEME="$vsname" python3 - "$cfg" <<'PY'
import os, sys

cfg = sys.argv[1]
theme = os.environ["NEW_THEME"]

with open(cfg) as f:
    lines = f.readlines()

out, patched = [], False
for ln in lines:
    if ln.strip().startswith('"workbench.colorTheme"'):
        indent = ln[: len(ln) - len(ln.lstrip())]
        out.append(f'{indent}"workbench.colorTheme": "{theme}",\n')
        patched = True
    else:
        out.append(ln)

if not patched:
    for i in range(len(out) - 1, -1, -1):
        if out[i].strip() == "}":
            if i > 0:
                prev = out[i - 1].rstrip()
                if not prev.endswith(","):
                    out[i - 1] = prev + ",\n"
            out.insert(i, f'  "workbench.colorTheme": "{theme}"\n')
            patched = True
            break

with open(cfg, "w") as f:
    f.writelines(out)
PY