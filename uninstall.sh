#!/bin/bash
# Desinstalle synology-office-handler (fichiers utilisateur uniquement).
set -euo pipefail

BIN="$HOME/.local/bin/syno-office-open"
DESKTOP="$HOME/.local/share/applications/synology-office-handler.desktop"
MIME_XML="$HOME/.local/share/mime/packages/x-synology-office.xml"

rm -f "$BIN" "$DESKTOP" "$MIME_XML"
# Icones posees par install.sh : dans hicolor ET dans le(s) theme(s)
# actif(s) du moment de l'installation. Retirer de tous les themes
# utilisateurs, SVG et PNG, noms normalises inclus (slide.svg).
for theme_dir in "$HOME"/.local/share/icons/*/; do
    rm -f "$theme_dir"scalable/mimetypes/application-x-synology-drive-*.svg
    rm -f "$theme_dir"[0-9]*x*/mimetypes/application-x-synology-drive-*.png
done
rmdir "$HOME/.local/bin" 2>/dev/null || true

update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "synology-office-handler desinstalle."
