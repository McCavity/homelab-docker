#!/usr/bin/env python3
"""Meldet neue Gokapi-Uploads per Telegram (über den ioBroker-Telegram-Adapter).

Gokapi kennt keine Webhooks. Jeder fertige Upload hinterläßt aber eine Zeile im
eigenen Protokoll (`<datenverzeichnis>/log.txt`):

    Thu, 29 Oct 2026 07:25:20 UTC   [upload] VTS_01_1.VOB, ID 6MIp…, uploaded to file request Qwqt… (Video Papa), owned by …

Dieses Skript läuft per systemd-Timer, liest die Zeilen seit dem letzten Lauf und
schickt je Lauf **eine** Nachricht über die ioBroker-SimpleAPI an
`telegram.0.communicate.response`. Die Dateigröße kommt schreibgeschützt aus der
Gokapi-Datenbank.

Zustand: Byte-Offset + Inode in STATE_FILE. Der Offset rückt nur nach einem
erfolgreichen Versand vor — scheitert der Versand, kommen die Zeilen beim
nächsten Lauf erneut. Beim allerersten Lauf wird nur der Offset gesetzt
(keine Altmeldungen). Schrumpft oder wechselt die Datei, beginnt es von vorn.

Konfiguration per Umgebung (systemd `EnvironmentFile`):
    IOBROKER_SIMPLEAPI   z.B. http://<host>:8087   (Pflicht)
    GOKAPI_LOG           Standard /mnt/gokapi/log.txt
    GOKAPI_DB            Standard /root/docker/dckapp01/gokapi/config/gokapi.sqlite
    STATE_FILE           Standard /var/lib/gokapi-upload-notify/state.json

`--dry-run` gibt die Nachricht nur aus und ändert keinen Zustand.
"""

import json
import os
import re
import sqlite3
import sys
import urllib.parse
import urllib.request

LOG = os.environ.get("GOKAPI_LOG", "/mnt/gokapi/log.txt")
DB = os.environ.get("GOKAPI_DB", "/root/docker/dckapp01/gokapi/config/gokapi.sqlite")
STATE = os.environ.get("STATE_FILE", "/var/lib/gokapi-upload-notify/state.json")
API = os.environ.get("IOBROKER_SIMPLEAPI", "").rstrip("/")
TARGET = "telegram.0.communicate.response"

UPLOAD_RE = re.compile(
    r"\[upload\] (?P<name>.+?), ID (?P<id>\w+), uploaded to file request \w+ \((?P<req>.*?)\)"
)


def load_state():
    try:
        with open(STATE) as f:
            return json.load(f)
    except FileNotFoundError:
        return None


def save_state(state):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, STATE)


def size_of(file_id):
    try:
        con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
        row = con.execute("select SizeBytes from FileMetaData where Id = ?", (file_id,)).fetchone()
        con.close()
    except sqlite3.Error:
        return ""
    if not row:
        return ""
    n = float(row[0])
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f" ({n:.1f} {unit})".replace(".", ",")
        n /= 1024


def build_message(uploads):
    by_req = {}
    for u in uploads:
        by_req.setdefault(u["req"], []).append(f"• {u['name']}{size_of(u['id'])}")
    head = "📤 Gokapi: neuer Upload" if len(uploads) == 1 else f"📤 Gokapi: {len(uploads)} neue Uploads"
    parts = [head]
    for req, lines in by_req.items():
        parts.append(f"\nAnfrage „{req}“:")
        parts.extend(lines)
    return "\n".join(parts)


def send(text):
    url = f"{API}/set/{TARGET}?" + urllib.parse.urlencode({"value": text})
    with urllib.request.urlopen(url, timeout=15) as r:
        body = r.read().decode("utf-8", "replace")
    if r.status != 200 or '"id"' not in body:
        raise RuntimeError(f"SimpleAPI antwortete {r.status}: {body[:200]}")


def main():
    dry = "--dry-run" in sys.argv
    if not API and not dry:
        sys.exit("IOBROKER_SIMPLEAPI ist nicht gesetzt")

    st = os.stat(LOG)
    state = load_state()
    if state is None:
        if not dry:
            save_state({"inode": st.st_ino, "offset": st.st_size})
        print(f"Erster Lauf: Offset auf {st.st_size} gesetzt, keine Altmeldungen.")
        return

    offset = state["offset"]
    if state.get("inode") != st.st_ino or st.st_size < offset:
        offset = 0

    with open(LOG, "rb") as f:
        f.seek(offset)
        chunk = f.read()
    # Nur vollständige Zeilen verarbeiten; ein angefangener Rest kommt beim nächsten Lauf.
    end = chunk.rfind(b"\n") + 1
    lines = chunk[:end].decode("utf-8", "replace").splitlines()

    uploads = [m.groupdict() for m in map(UPLOAD_RE.search, lines) if m]
    if uploads:
        text = build_message(uploads)
        if dry:
            print(text)
            return
        send(text)
    if not dry:
        save_state({"inode": st.st_ino, "offset": offset + end})


if __name__ == "__main__":
    main()
