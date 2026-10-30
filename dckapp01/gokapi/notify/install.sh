#!/bin/sh
# Installiert den Upload-Melder auf dckapp01. Aus diesem Verzeichnis als root ausführen.
# Die ioBroker-Adresse steht nur auf dem Host (/etc/default/gokapi-upload-notify), nicht im Repo.
set -eu
cd "$(dirname "$0")"
install -m 0755 gokapi-upload-notify.py /usr/local/bin/gokapi-upload-notify
install -m 0644 gokapi-upload-notify.service gokapi-upload-notify.timer /etc/systemd/system/
if [ ! -f /etc/default/gokapi-upload-notify ]; then
  echo 'IOBROKER_SIMPLEAPI=http://HOST:8087' > /etc/default/gokapi-upload-notify
  echo "Bitte /etc/default/gokapi-upload-notify anpassen, dann erneut ausführen." >&2
  exit 1
fi
systemctl daemon-reload
systemctl enable --now gokapi-upload-notify.timer
systemctl list-timers gokapi-upload-notify.timer --no-pager
