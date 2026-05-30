# Homelab Docker Stacks

> Letzte Aktualisierung: 2026-05-30
> Quelle der Wahrheit für Docker-Compose-Stacks im Homelab. Pro Host ein Subdir, sparse-checkout pro Host.

## Hosts

| Subdir | Host | Stacks |
|---|---|---|
| [`dckapp01/`](dckapp01/) | dckapp01 (192.168.178.156) auf pveapp01 | ghost, dockge, unifi-poller |
| [`paperless-ngx/`](paperless-ngx/) | paperless-ngx (192.168.178.168) auf pveapp02 | paperless-ngx-Stack (db, broker, webserver, gotenberg, tika) |

## Setup auf einem neuen Host (sparse-checkout)

```bash
# Beispiel paperless-ngx-Host:
git clone --filter=blob:none --no-checkout git@github.com:McCavity/homelab-docker.git /home/paperless
cd /home/paperless
git sparse-checkout init --cone
git sparse-checkout set paperless-ngx
git checkout main

# Pro Stack: .env aus .env.example, Secrets aus 1Password
cd paperless-ngx
cp .env.example .env  # editieren
docker compose up -d
```

Vollständiges Setup-Beispiel pro Host in dessen README.

## Secret-Management

Compose-Files referenzieren Secrets über Umgebungsvariablen (`${VAR_NAME}`), die aus einer `.env`-Datei im selben Verzeichnis gelesen werden. Die `.env`-Dateien sind **nicht** im Repo (siehe `.gitignore`).

**Defense in Depth:**

1. `.env`-Files leben lokal auf dem Docker-Host
2. Werden mit dem Proxmox-LXC-Backup gesichert (NAS, täglich)
3. Sind zusätzlich in 1Password als Secure Note „<host> .env" hinterlegt (Cloud-synchronisiert, Site-unabhängiger Restore-Pfad)

Beim Anlegen oder Ändern einer `.env`-Datei: **1Password-Eintrag mit aktualisieren.**

1Password-Konvention: pro Host ein Eintrag `<host> .env` (z.B. „dckapp01 .env", „paperless-ngx .env").

## Verwandte Projekte / Hosts

- `gfaapp01` (192.168.178.162) — Grafana, visualisiert die unifi-poller-Daten
- `idbapp01` (192.168.178.161) — InfluxDB, empfängt die Time-Series von unifi-poller
- UDM (10.10.0.1) — UniFi Controller, Datenquelle für unifi-poller
