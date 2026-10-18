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
DRIVE_IMAGES="$HOME/.SynologyDrive/SynologyDrive.app/images"

mkdir -p "$BIN_DIR" "$APP_DIR" "$MIME_DIR"

# 1. Lanceur
install -m 0755 "$PROJECT_DIR/syno-office-open" "$BIN_DIR/syno-office-open"

# 2. Entree desktop (Exec avec chemin absolu pour fiabilite)
sed "s|^Exec=.*|Exec=$BIN_DIR/syno-office-open %f|" \
    "$PROJECT_DIR/synology-office-handler.desktop" \
    > "$APP_DIR/synology-office-handler.desktop"

# 3. Types MIME
install -m 0644 "$PROJECT_DIR/x-synology-office.xml" "$MIME_DIR/x-synology-office.xml"

# 4. Icones du client Drive, si disponibles (meilleurs reperes visuels).
#    Le client embarque "slides.svg" mais le type MIME officiel est
#    x-synology-drive-slide (sans s) : normaliser le nom pour que le
#    gestionnaire de fichiers retrouve l'icone (recherche par type MIME).
#
#    GTK resout l'icone d'un fichier en essayant les noms du type MIME
#    puis application-x-generic, et prefere a distance egale le nom trouve
#    dans le theme actif. Une icone posee seulement dans hicolor est donc
#    systematiquement ecrasee par le generic du theme : il faut aussi la
#    poser dans le repertoire utilisateur du theme actif, en SVG scalable
#    et en PNG aux tailles courantes (un raster exact du theme battrait
#    notre SVG scalable a distance egale).

ICON_THEME=""
if command -v gsettings >/dev/null 2>&1; then
    for schema in org.cinnamon.desktop.interface org.gnome.desktop.interface; do
        candidat="$(gsettings get "$schema" icon-theme 2>/dev/null | tr -d "'" || true)"
        if [ -n "$candidat" ]; then
            ICON_THEME="$candidat"
            break
        fi
    done
fi

THEMES=(hicolor)
if [ -n "$ICON_THEME" ] && [ "$ICON_THEME" != "hicolor" ]; then
    THEMES+=("$ICON_THEME")
fi
[ -n "$ICON_THEME" ] && echo "Theme d'icones actif detecte : $ICON_THEME"

if [ -d "$DRIVE_IMAGES" ]; then
    for svg in "$DRIVE_IMAGES"/application-x-synology-drive-*.svg; do
        [ -f "$svg" ] || continue
        nom="$(basename "$svg")"
        nom="${nom/slides.svg/slide.svg}"
        nom_png="${nom%.svg}"
        for theme in "${THEMES[@]}"; do
            theme_dir="$HOME/.local/share/icons/$theme"
            mkdir -p "$theme_dir/scalable/mimetypes"
            install -m 0644 "$svg" "$theme_dir/scalable/mimetypes/$nom"
            if command -v gdk-pixbuf-thumbnailer >/dev/null 2>&1; then
                for taille in 16 22 24 32 48 64 96 128; do
                    mkdir -p "$theme_dir/${taille}x${taille}/mimetypes"
                    gdk-pixbuf-thumbnailer -s "$taille" "$svg" \
                        "$theme_dir/${taille}x${taille}/mimetypes/$nom_png.png" \
                        2>/dev/null || true
                done
            fi
        done
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
