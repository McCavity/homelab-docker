#!/bin/bash
# Skript: restore.sh
# Dieses Skript stellt ein Backup wieder her.

set -e

echo "Starte Wiederherstellung: Das Backup wird nun wiederhergestellt..."

DOCKER_COMPOSE_FILE="$(dirname "$0")/docker-compose.yml"

# Funktion zum Auskommentieren der Umgebungsvariablen in docker-compose.yml
comment_out_env_vars() {
  echo "Kommentiere PAPERLESS_ADMIN_USER und PAPERLESS_ADMIN_PASSWORD in der docker-compose.yml aus..."

  # Erstelle ein Backup der Datei, falls noch nicht gesichert
  if [ ! -f "${DOCKER_COMPOSE_FILE}.bak" ]; then
    sudo cp "$DOCKER_COMPOSE_FILE" "${DOCKER_COMPOSE_FILE}.bak"
  fi

  # Setze sicherheitshalber Schreibrechte
  sudo chmod u+w "$DOCKER_COMPOSE_FILE"

  # Füge das `#` nur hinzu, falls es noch nicht vorhanden ist
  sudo sed -i 's/^\( *PAPERLESS_ADMIN_USER: \)/#\1/' "$DOCKER_COMPOSE_FILE"
  sudo sed -i 's/^\( *PAPERLESS_ADMIN_PASSWORD: \)/#\1/' "$DOCKER_COMPOSE_FILE"

  echo "Variablen erfolgreich auskommentiert."
}

# Variablen auskommentieren, bevor das Skript weiterläuft
comment_out_env_vars

# Verzeichnisse definieren
BACKUP_DIR="/data/paperless/restore"
EXPORT_DIR="/data/paperless/export"
DIRECTORIES_TO_DELETE=(
  "/data/paperless/consume"
  "/data/paperless/export"
  "/data/paperless/media"
  "/data/paperless/postgresql"
  "/data/paperless/redis"
)

# Prüfe, ob das Backup-Verzeichnis existiert
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Fehler: Backup-Verzeichnis $BACKUP_DIR existiert nicht."
  exit 1
fi

# Schritt 1: Docker Compose herunterfahren
echo "Wechsle ins Stack-Verzeichnis und fahre Docker Compose herunter..."
cd "$(dirname "$0")" || { echo "Fehler: Stack-Verzeichnis nicht gefunden."; exit 1; }
sudo docker compose down

# Schritt 2: Lösche die angegebenen Verzeichnisse
echo "Lösche die folgenden Verzeichnisse:"
for dir in "${DIRECTORIES_TO_DELETE[@]}"; do
  echo "  $dir"
  if [ -d "$dir" ]; then
    sudo rm -rf "$dir"
    echo "    -> $dir gelöscht."
  else
    echo "    -> $dir existiert nicht, überspringe..."
  fi
done

# Schritt 3: Erstelle das Export-Verzeichnis neu
echo "Erstelle das Verzeichnis $EXPORT_DIR..."
sudo mkdir -p "$EXPORT_DIR"
if [ $? -ne 0 ]; then
  echo "Fehler: Konnte $EXPORT_DIR nicht erstellen."
  exit 1
fi

# Schritt 4: Suche nach einer Archivdatei im Backup-Verzeichnis (z. B. *.zip)
ARCHIVE_FILE=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.zip" | head -n 1)
if [ -z "$ARCHIVE_FILE" ]; then
  echo "Fehler: Keine Archivdatei (*.zip) im Backup-Verzeichnis gefunden."
  exit 1
fi
echo "Gefundene Archivdatei: $ARCHIVE_FILE"

# Schritt 5: Kopiere die Archivdatei in das Export-Verzeichnis
echo "Kopiere die Archivdatei nach $EXPORT_DIR..."
sudo cp "$ARCHIVE_FILE" "$EXPORT_DIR"
if [ $? -ne 0 ]; then
  echo "Fehler beim Kopieren der Archivdatei."
  exit 1
fi

# Schritt 6: Wechsel in das Export-Verzeichnis und entpacke die Archivdatei
cd "$EXPORT_DIR" || { echo "Fehler: Konnte nicht in $EXPORT_DIR wechseln."; exit 1; }

# Überprüfe, ob 'unzip' installiert ist und installiere es gegebenenfalls
if ! command -v unzip >/dev/null 2>&1; then
  echo "Das Paket 'unzip' ist nicht installiert. Versuche, es zu installieren..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y unzip
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y unzip
  else
    echo "Kein unterstützter Paketmanager gefunden. Bitte installiere 'unzip' manuell."
    exit 1
  fi
fi

# Entpacken der Archivdatei
ARCHIVE_BASENAME=$(basename "$ARCHIVE_FILE")
echo "Entpacke $ARCHIVE_BASENAME..."
unzip "$ARCHIVE_BASENAME"
if [ $? -ne 0 ]; then
  echo "Fehler beim Entpacken von $ARCHIVE_BASENAME."
  exit 1
fi
echo "Archiv erfolgreich entpackt."

# Optional: Entferne die kopierte Archivdatei, falls sie nicht mehr benötigt wird
# sudo rm "$ARCHIVE_BASENAME"

# Schritt 7: Starte Docker Compose Container neu
echo "Wechsle zurück ins Stack-Verzeichnis und starte die Container..."
cd "$(dirname "$0")" || { echo "Fehler: Stack-Verzeichnis nicht gefunden."; exit 1; }
sudo -u paperless docker compose up -d
if [ $? -ne 0 ]; then
  echo "Fehler: Docker Compose konnte nicht gestartet werden."
  exit 1
fi

sudo chown -R paperless:paperless /data/paperless/consume /data/paperless/media
sudo chmod -R 775 /data/paperless/consume /data/paperless/media
sudo chown paperless:paperless "$(dirname "$0")/docker-compose.yml"


sleep 60

cd "$(dirname "$0")"
# Schritt 8: Führe den Importbefehl aus
echo "Führe Importbefehl aus..."
sudo docker compose exec webserver document_importer ../export
sudo chown -R paperless:paperless /data/paperless 
if [ $? -eq 0 ]; then
  echo "Import erfolgreich abgeschlossen."
else
  echo "Fehler beim Import."
  exit 1
fi
echo " Bitte einmal das System neu booten ! "
echo "---------------------------ENDE--------------------------------"