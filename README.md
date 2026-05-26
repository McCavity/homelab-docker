# Homelab Docker Stacks

> Letzte Aktualisierung: 2026-05-26
> Quelle der Wahrheit für Docker-Compose-Stacks auf `dckapp01` (192.168.178.156).

## Stacks

| Verzeichnis | Beschreibung | Aktiv |
|---|---|---|
| [`ghost/`](ghost/) | Ghost CMS (Blog) + MySQL + phpMyAdmin | Ja, geplante Migration zu eigenem VuZ-Stack mittelfristig |
| [`unifi-poller/`](unifi-poller/) | unpoller (vormals golift/unifi-poller) → InfluxDB → Grafana. Verzeichnisname historisch. | Ja, produktiv |
| [`dockge/`](dockge/) | Dockge — Web-UI für Docker-Stacks (Portainer-Nachfolger) | Ja, produktiv |

## Setup auf einem neuen Host

```bash
# 1. Repo klonen
git clone git@github.com:McCavity/homelab-docker.git ~/docker
cd ~/docker

# 2. Pro Stack: .env aus .env.example anlegen und befüllen
cp ghost/.env.example ghost/.env
cp unifi-poller/.env.example unifi-poller/.env
# Editieren, Secrets aus 1Password kopieren

# 3. Stack starten
cd ghost && docker compose up -d
cd ../unifi-poller && docker compose up -d
```

## Secret-Management

Compose-Files referenzieren Secrets über Umgebungsvariablen (`${VAR_NAME}`), die aus einer `.env`-Datei im selben Verzeichnis gelesen werden. Die `.env`-Dateien sind **nicht** im Repo (siehe `.gitignore`).

**Defense in Depth:**

1. `.env`-Files leben lokal auf dem Docker-Host
2. Werden mit dem Proxmox-LXC-Backup gesichert (NAS, täglich)
3. Sind zusätzlich in 1Password als Secure Note „homelab-docker .env" hinterlegt (Cloud-synchronisiert, Site-unabhängiger Restore-Pfad)

Beim Anlegen oder Ändern einer `.env`-Datei: **1Password-Eintrag mit aktualisieren.**

## Verwandte Projekte / Hosts

- `gfaapp01` (192.168.178.162) — Grafana, visualisiert die unifi-poller-Daten
- `idbapp01` (192.168.178.161) — InfluxDB, empfängt die Time-Series von unifi-poller
- UDM (10.10.0.1) — UniFi Controller, Datenquelle für unifi-poller
