#!/bin/bash
# Installe synology-office-handler pour l'utilisateur courant :
#  - lanceur dans ~/.local/bin
#  - entree desktop dans ~/.local/share/applications
#  - types MIME dans ~/.local/share/mime
#  - icones officielles du client Drive dans ~/.local/share/icons (si presentes)
#
# Aucune configuration n'est necessaire : le lanceur delegue l'ouverture
# au client Synology Drive deja installe, qui gere seul l'authentification.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
MIME_DIR="$HOME/.local/share/mime/packages"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/mimetypes"
DRIVE_IMAGES="$HOME/.SynologyDrive/SynologyDrive.app/images"

mkdir -p "$BIN_DIR" "$APP_DIR" "$MIME_DIR" "$ICON_DIR"

# 1. Lanceur
install -m 0755 "$PROJECT_DIR/syno-office-open" "$BIN_DIR/syno-office-open"

# 2. Entree desktop (Exec avec chemin absolu pour fiabilite)
sed "s|^Exec=.*|Exec=$BIN_DIR/syno-office-open %f|" \
    "$PROJECT_DIR/synology-office-handler.desktop" \
    > "$APP_DIR/synology-office-handler.desktop"

# 3. Types MIME
install -m 0644 "$PROJECT_DIR/x-synology-office.xml" "$MIME_DIR/x-synology-office.xml"

# 4. Icones du client Drive, si disponible (meilleurs reperes visuels)
if [ -d "$DRIVE_IMAGES" ]; then
    for svg in "$DRIVE_IMAGES"/application-x-synology-drive-*.svg; do
        [ -f "$svg" ] || continue
        install -m 0644 "$svg" "$ICON_DIR/"
    done
fi

# 5. Bases de donnees MIME/desktop
update-mime-database "$HOME/.local/share/mime"
update-desktop-database "$APP_DIR" 2>/dev/null || true

# 6. Associations par defaut
for type in application/x-synology-drive-sheet \
            application/x-synology-drive-doc \
            application/x-synology-drive-slide; do
    xdg-mime default synology-office-handler.desktop "$type"
done

echo ""
echo "Installation terminee."
echo "Aucune configuration n'est requise : le client Synology Drive doit"
echo "simplement etre installe et connecte (flatpak com.synology.SynologyDrive)."
echo "Testez avec : $BIN_DIR/syno-office-open <fichier.osheet>"
