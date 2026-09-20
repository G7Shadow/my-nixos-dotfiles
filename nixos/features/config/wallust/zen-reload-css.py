#!/usr/bin/env python3
"""Attempt to hot-reload Zen's userChrome.css via Firefox Browser Toolbox RDP.

Firefox/Zen loads userChrome.css once at startup. The ONLY way to live-reload
it without restarting is through the Browser Toolbox (Ctrl+Shift+Alt+I),
which watches for file changes. This script tries to trigger that reload
via the RDP WebSocket. Falls back to a notification if unavailable.

Usage: zen-reload-css.py [port]
  Default port: 6000 (Browser Toolbox's default debugger port)
"""

import socket
import os
import struct
import json
import sys
import subprocess
import time

WS_TEXT = 0x01
WS_CLOSE = 0x08
WS_PING = 0x09
WS_PONG = 0x0A


def _frame(opcode, payload):
    buf = bytearray([0x80 | opcode])
    n = len(payload)
    if n < 126:
        buf.append(n)
    elif n < 65536:
        buf.append(126)
        buf.extend(struct.pack(">H", n))
    else:
        buf.append(127)
        buf.extend(struct.pack(">Q", n))
    buf.extend(payload)
    return bytes(buf)


def _recv(sock, timeout=3):
    sock.settimeout(timeout)
    try:
        hdr = sock.recv(2)
    except socket.timeout:
        return None
    if len(hdr) < 2:
        return None
    ln = hdr[1] & 0x7F
    if ln == 126:
        ln = struct.unpack(">H", sock.recv(2))[0]
    elif ln == 127:
        ln = struct.unpack(">Q", sock.recv(8))[0]
    data = b""
    while len(data) < ln:
        ch = sock.recv(ln - len(data))
        if not ch:
            return None
        data += ch
    op = hdr[0] & 0x0F
    if op == WS_CLOSE:
        return None
    if op == WS_PING:
        sock.sendall(_frame(WS_PONG, data))
        return _recv(sock, timeout)
    try:
        return json.loads(data.decode())
    except Exception:
        return None


def _send(sock, obj):
    sock.sendall(_frame(WS_TEXT, json.dumps(obj).encode()))


def try_rdp_reload(port=6000):
    """Try to trigger CSS reload via Firefox Browser Toolbox RDP.

    Requires the Browser Toolbox to be open (Ctrl+Shift+Alt+I).
    The Browser Toolbox watches userChrome.css for changes and auto-reloads.
    This script connects to its WebSocket and sends a reload command.
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(3)
    try:
        sock.connect(("127.0.0.1", port))
    except (ConnectionRefusedError, OSError):
        return False

    try:
        import base64
        key = base64.b64encode(os.urandom(16)).decode()
        req = (
            f"GET / HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\n"
            "Upgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
        )
        sock.sendall(req.encode())
        resp = b""
        while b"\r\n\r\n" not in resp:
            ch = sock.recv(4096)
            if not ch:
                return False
            resp += ch
        if b"101" not in resp.split(b"\r\n")[0]:
            return False

        hello = _recv(sock, timeout=3)
        if not hello:
            return False

        _send(sock, {"from": "client", "to": "root", "type": "root", "id": "r1"})
        root = _recv(sock, timeout=3)
        if not root:
            return False

        _send(sock, {"from": "client", "to": "root", "type": "listTabs", "id": "t1"})
        tabs_resp = _recv(sock, timeout=3)
        if not tabs_resp:
            return False

        tabs = tabs_resp.get("tabs", [])
        if not tabs:
            return False

        tab_actor = tabs[0].get("actor")
        if not tab_actor:
            return False

        _send(sock, {"from": "client", "to": tab_actor, "type": "attach", "id": "a1"})
        _recv(sock, timeout=3)
        _recv(sock, timeout=0.5)

        _send(sock, {
            "from": "client", "to": tab_actor, "id": "j1",
            "type": "evaluateJSAsync",
            "text": """(function(){
                try {
                    let obs = Components.classes["@mozilla.org/observer-service;1"]
                        .getService(Components.interfaces.nsIObserverService);
                    obs.notifyObservers(null, "devtools-reload-userchrome");
                    return "reloaded";
                } catch(e) { return "err:" + e; }
            })()"""
        })
        _recv(sock, timeout=5)
        _recv(sock, timeout=0.5)
        return True
    except Exception:
        return False
    finally:
        try:
            sock.close()
        except Exception:
            pass


def notify(msg):
    try:
        subprocess.run(
            ["notify-send", "Zen CSS", msg, "-t", "3000"],
            timeout=5, capture_output=True
        )
    except Exception:
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 6000
    if try_rdp_reload(port):
        print("Zen CSS reloaded via RDP")
    else:
        notify("Open Browser Toolbox (Ctrl+Shift+Alt+I) for live CSS reload")
