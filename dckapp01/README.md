# dckapp01

> LXC `dckapp01` (192.168.178.156) auf pveapp01 — primärer Docker-Host fürs Homelab.

## Stacks

| Verzeichnis | Beschreibung | Status |
|---|---|---|
| [`unifi-poller/`](unifi-poller/) | unpoller (vormals golift/unifi-poller) → InfluxDB → Grafana | produktiv |
| [`ghost/`](ghost/) | Ghost CMS (Blog) + MySQL + phpMyAdmin | **stillgelegt 24.10.2026** (`docker compose down`, Archiv auf dem Host unter `/root/archiv/`); Tunnel-Routen `cmsadmin`/`cmsmyadmin` am 26.10. entfernt |
| [`gokapi/`](gokapi/) | Gokapi — Upload-/Download-Links (upload.halfpap.io) | im Aufbau, erprobt 26.10.2026 |
| [`dockge/`](dockge/) | Dockge — Web-UI für Docker-Stacks (Portainer-Nachfolger) | produktiv |

## Setup auf einem neuen Host

```bash
# Sparse-Checkout: nur dckapp01-Subdir
git clone --filter=blob:none --no-checkout git@github.com:McCavity/homelab-docker.git ~/docker
cd ~/docker
git sparse-checkout init --cone
git sparse-checkout set dckapp01
git checkout main

# Pro Stack: .env aus .env.example, Secrets aus 1Password
cd dckapp01/unifi-poller
cp .env.example .env  # editieren
docker compose up -d
```
