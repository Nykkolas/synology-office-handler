#!/bin/bash
# Desinstalle synology-office-handler (fichiers utilisateur uniquement).
set -euo pipefail

BIN="$HOME/.local/bin/syno-office-open"
DESKTOP="$HOME/.local/share/applications/synology-office-handler.desktop"
MIME_XML="$HOME/.local/share/mime/packages/x-synology-office.xml"
ICONS="$HOME/.local/share/icons/hicolor/scalable/mimetypes"

rm -f "$BIN" "$DESKTOP" "$MIME_XML"
rm -f "$ICONS"/application-x-synology-drive-{sheet,doc,slide}.svg
rmdir "$HOME/.local/bin" 2>/dev/null || true

update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "synology-office-handler desinstalle."
