#!/bin/bash
# Skript: backup.sh
# Dieses Skript führt ein Backup über docker-compose aus und verschiebt anschließend die Backup-Datei(en).

echo "Starte Backup: Ein Backup wird jetzt durchgeführt..."

# Wechsel in das Verzeichnis, in dem sich die docker-compose Datei befindet
cd "$(dirname "$0")" || { echo "Fehler: Stack-Verzeichnis nicht gefunden."; exit 1; }

# Führe den docker-compose Befehl aus
sudo docker compose exec webserver document_exporter ../export -z

# Prüfe, ob der Befehl erfolgreich war
if [ $? -eq 0 ]; then
  echo "Backup erfolgreich abgeschlossen."
  
  # Prüfen, ob das Quellverzeichnis existiert
  if [ -d "/data/paperless/export" ]; then
    # Sicherstellen, dass das Zielverzeichnis existiert (falls nicht, wird es angelegt)
    mkdir -p /data/paperless/backup

    # Prüfen, ob im Quellverzeichnis Dateien vorhanden sind
    if compgen -G "/data/paperless/export/*" > /dev/null; then
      echo "Verschiebe Backup-Datei(en) nach /data/paperless/backup..."
      mv /data/paperless/export/* /data/paperless/backup/
      
      if [ $? -eq 0 ]; then
        echo "Datei(en) erfolgreich verschoben."
      else
        echo "Fehler beim Verschieben der Datei(en)."
      fi
    else
      echo "Keine Datei(en) im Verzeichnis /data/paperless/export gefunden."
    fi
  else
    echo "Quellverzeichnis /data/paperless/export existiert nicht."
  fi
else
  echo "Fehler beim Backup."
fi