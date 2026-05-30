# paperless-ngx

> LXC `paperless-ngx` (192.168.178.168) auf pveapp02 — eigene Docker-Instanz, nicht auf dckapp01.
> URLs: `http://paperless-ngx.lan:8001`, `http://192.168.178.168:8001`, `https://archiv.hennings-netzwerk.de` (Cloudflare-Tunnel).

## Stack

- `webserver` — Paperless-NGX (`ghcr.io/paperless-ngx/paperless-ngx:latest`)
- `db` — PostgreSQL 16
- `broker` — Redis 7
- `gotenberg` — PDF-Konvertierung
- `tika` — Volltext-Extraktion

## Setup

```bash
cp .env.example .env
# Werte aus 1Password "paperless-ngx .env" einsetzen
docker compose up -d
```

## Scripts

| Script | Zweck |
|---|---|
| `backup.sh` | Paperless-Export → `/data/paperless/backup/` |
| `restore.sh` | Backup zurückspielen (Datenverlust-Pfad, mit Vorsicht!) |
| `install_paperless.sh` | Fresh-Install-Script (Bootstrap, deprecated bei Repo-Setup — nur Referenz für historische Provisionierung) |

## Bind-Mount-Pfade (nicht im Repo)

- `/data/paperless/consume` — Eingang (auch via Samba erreichbar)
- `/data/paperless/data` — Suchindex
- `/data/paperless/media` — Originale + OCR-Sidecars
- `/data/paperless/export` — Export-Targets
- `/data/paperless/redis/_data`, `/data/paperless/postgresql/_data` — Container-Volumes

Backup: Proxmox-LXC-Snapshot auf NAS täglich.
