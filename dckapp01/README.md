# dckapp01

> LXC `dckapp01` (192.168.178.156) auf pveapp01 — primärer Docker-Host fürs Homelab.

## Stacks

| Verzeichnis | Beschreibung | Status |
|---|---|---|
| [`unifi-poller/`](unifi-poller/) | unpoller (vormals golift/unifi-poller) → InfluxDB → Grafana | produktiv |
| [`ghost/`](ghost/) | Ghost CMS (Blog) + MySQL + phpMyAdmin | aktiv, geplante Ablösung durch eigenen VuZ-Stack |
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
