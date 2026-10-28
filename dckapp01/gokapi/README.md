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
