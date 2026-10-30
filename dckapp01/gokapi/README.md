# Gokapi

> Angelegt: 2026-10-26. Self-hosted Datei-Austausch: Upload-Anfragen (Link mit Ablauf, ohne Konto) und Download-Links.

## Warum Gokapi

Gegen Pingvin Share X, Erugo, PsiTransfer, Zipline, Sharry und die Synology-Dateianforderung abgewogen (26.10.2026).
Ausschlaggebend: Upload in Stücken unter 100 MB (Cloudflare-Tunnel, Free-Plan), Upload-Anfragen mit Ablauf und
Grenzen, vollständige REST-API zur Verwaltung aus einer Session.

## Wichtig im Betrieb

- **Sperren = Ablaufdatum in die Vergangenheit setzen, nie löschen.** Löschen einer Upload-Anfrage löscht ihre
  Dateien mit (gemessen 26.10.: 2 Dateien → 0). Dateien aus Anfragen sind fest „unbegrenzt“ und überleben den Ablauf.
- **„Max. Größe“ gilt pro Datei**, nicht als Summe (Code: `MaxSize` „maximum file size allowed in MB“).
- Deutsche Oberfläche: Gokapi hat keine Übersetzungen. `custom/public.js` übersetzt die öffentlichen Seiten
  (Liste englisch → deutsch). Nach einem Gokapi-Update fehlende Texte dort ergänzen und `custom/version.txt` erhöhen.
- **Daten auf dem NAS** (Share `gokapi`, NFSv3 — das NAS lehnt 4.1 ab). Kette: NAS → `pveapp01:/mnt/gokapi` (`/etc/fstab`,
  `nofail`) → `mp0` in CT 106 (`backup=0`) → `/mnt/gokapi` → `/app/data`. Das leere Verzeichnis unter dem Mountpunkt auf
  `pveapp01` ist `chattr +i`: Fehlt das NFS beim Booten, scheitern Uploads laut, statt still auf der Hostplatte zu landen.
- **`config/` bleibt im Stack-Ordner** und ist per `.gitignore` ausgeschlossen. Das Repo ist öffentlich — nie `git add -A`
  auf dem Host.

## Upload-Meldung per Telegram (`notify/`)

Gokapi kennt keine Webhooks. `notify/gokapi-upload-notify.py` liest jede Minute (systemd-Timer) die neuen
`[upload]`-Zeilen aus `/mnt/gokapi/log.txt` und schickt je Lauf eine Nachricht über die ioBroker-SimpleAPI an
`telegram.0.communicate.response` — derselbe Bot und Chat wie die übrigen Hausmeldungen.

- Installation auf dem Host: `notify/install.sh` als root. Die SimpleAPI-Adresse steht nur in
  `/etc/default/gokapi-upload-notify`, nicht im Repo.
- Der Offset rückt nur nach erfolgreichem Versand vor; scheitert der Versand, kommt die Meldung beim nächsten Lauf.
- Probe ohne Versand: `python3 /usr/local/bin/gokapi-upload-notify --dry-run`.
- Geprüft 30.10.2026: Ende-zu-Ende durch den Tunnel (Meldung von ioBroker quittiert), Fehlerpfad isoliert
  (falsche Adresse → Exit 1, Offset bleibt; danach richtige Adresse → Meldung kommt nach).
- Gokapis `log.txt` enthält **nur Erfolge**. Abgebrochene Stücke sieht man ausschließlich im cloudflared-Log
  („Incoming request ended abruptly: context canceled“ auf `/api/uploadrequest/chunk/add`).

## Dateien direkt vom NAS holen (`tools/gokapi-holen`)

Gokapi legt jede Datei unter der **SHA1 ihres Inhalts** ab; der Klarname steht nur in der Datenbank. Der Download über
die Admin-Seite läuft durch den Tunnel und ist entsprechend langsam. `tools/gokapi-holen "<Anfrage>"` liest die
Zuordnung schreibgeschützt per ssh und kopiert aus dem gemounteten Share (`/Volumes/gokapi`) mit Klarnamen nach
`~/Downloads/gokapi/<Anfrage>/`. Die SHA1 wird beim Kopieren geprüft, nichts wird überschrieben.

Den Share am Mac **nur lesend** nutzen (DSM: Benutzer nur „Schreibgeschützt“ auf `gokapi`). Der Finder legt sonst
`.DS_Store` in Gokapis Datenverzeichnis.

## Stückgröße für langsame Leitungen

`config/config.json`: **`ChunkSize` 10** (MB) und **`MaxParallelUploads` 1** (seit 30.10.2026, vorher 45/3). Anlaß: Beim
ersten echten Upload (~1 MB/s Upload beim Absender) brachen 45-MB-Stücke ab; die Seite meldete „Serverfehler“ und
versuchte es dreimal. Mit 10 MB dauert ein Stück auch bei 600 KB/s unter 20 s, und ein Abbruch kostet nur 10 MB.
`CHUNK_SIZE` landet in der öffentlichen Seite (`const CHUNK_SIZE = 10 * 1024 * 1024`) — dort prüfen, nicht in der Datei.
Änderung erst nach `docker restart gokapi` wirksam.

Skript-Zugriffe auf die öffentliche Seite durch den Tunnel brauchen einen User-Agent: Cloudflare antwortet dem
Python-Standard-Agenten mit 403.
