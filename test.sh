#!/bin/bash
# Tests fonctionnels de synology-office-handler dans un HOME sable :
# le lanceur, install.sh et uninstall.sh sont executes avec un HOME
# temporaire, un faux client Drive et des stubs (flatpak absent,
# notify-send muet). Rien n'est touche sur la machine.
# Prerequis : xdg-utils (deja prerequis du projet).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

export HOME="$SANDBOX/home"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$HOME"

# Hermeticite : ne pas heriter de LD_LIBRARY_PATH de la session appelante
# (il peut casser les outils systeme invoques par install.sh, ex.
# update-mime-database avec une libstdc++ inadaptee).
unset LD_LIBRARY_PATH

# Stubs devant masquer les commandes reelles :
#  - flatpak : "info" echoue ; "run --command=sh APP -c SCRIPT sh FICHIER"
#    execute SCRIPT avec FICHIER, comme le vrai bac a sable (indispensable
#    sur une machine ou com.synology.SynologyDrive est reellement installee,
#    car le lanceur la detecte via /var/lib/flatpak) ;
#  - notify-send : muet, pas de notification bureau pendant les tests.
STUB_DIR="$SANDBOX/stub"
mkdir -p "$STUB_DIR"
cat > "$STUB_DIR/flatpak" <<'EOF'
#!/bin/bash
case "${1:-}" in
    info) exit 1 ;;
    run)
        shift
        while [ "$1" != "-c" ]; do shift; done
        shift
        script="$1"
        shift
        exec sh -c "$script" "$@"
        ;;
esac
exit 0
EOF
printf '#!/bin/bash\nexit 0\n' > "$STUB_DIR/notify-send"
chmod +x "$STUB_DIR"/*
export PATH="$STUB_DIR:$PATH"

# Faux client Drive : journalise ses arguments puis reussit.
UI_LOG="$SANDBOX/ui.log"
export UI_LOG
UI_BIN="$HOME/.SynologyDrive/SynologyDrive.app/bin/cloud-drive-ui"
mkdir -p "$(dirname "$UI_BIN")"
cat > "$UI_BIN" <<'EOF'
#!/bin/bash
echo "$@" >> "$UI_LOG"
exit 0
EOF
chmod +x "$UI_BIN"

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); echo "ok : $1"; }
ko() { FAIL=$((FAIL + 1)); echo "KO : $1"; }

attend_un_echec() { # <description> <cmd...> : doit echouer (exit non nul)
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then ko "$desc (aurait du echouer)"; else ok "$desc"; fi
}

attend_un_succes() { # <description> <cmd...> : doit reussir (exit 0)
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$desc"; else ko "$desc (aurait du reussir)"; fi
}

LAUNCHER="$PROJECT_DIR/syno-office-open"

# 1. Chemins d'erreur du lanceur
attend_un_echec "sans argument : refus" "$LAUNCHER"
attend_un_echec "fichier inexistant : refus" "$LAUNCHER" "$HOME/absent.osheet"
attend_un_echec "extension non geree : refus" "$LAUNCHER" /etc/hostname
attend_un_echec "client Drive absent : refus" \
    env HOME="$SANDBOX/home2" "$LAUNCHER" "$LAUNCHER"

# 2. Delegation au client Drive
: > "$UI_LOG"
DOSSIER="$HOME/Dossier Test"
mkdir -p "$DOSSIER"
: > "$DOSSIER/Feuille test 1.osheet"
attend_un_succes "ouverture d'un .osheet avec espaces" \
    "$LAUNCHER" "$DOSSIER/Feuille test 1.osheet"
if grep -qF -- "--open-file $DOSSIER/Feuille test 1.osheet" "$UI_LOG"; then
    ok "chemin absolu transmis au client, espaces preserves"
else
    ko "arguments recus par le client : $(cat "$UI_LOG")"
fi

: > "$UI_LOG"
: > "$DOSSIER/PRESENTATION.OSLIDES"
attend_un_succes "extension majuscule acceptee" \
    "$LAUNCHER" "$DOSSIER/PRESENTATION.OSLIDES"
[ -s "$UI_LOG" ] && ok "client appele" || ko "client non appele"

# 3. install.sh dans le HOME sable (fausses icones Drive embarquees)
DRIVE_IMAGES="$HOME/.SynologyDrive/SynologyDrive.app/images"
mkdir -p "$DRIVE_IMAGES"
for nom in sheet doc slides; do
    : > "$DRIVE_IMAGES/application-x-synology-drive-$nom.svg"
done

attend_un_succes "install.sh" "$PROJECT_DIR/install.sh"

BIN="$HOME/.local/bin/syno-office-open"
DESKTOP="$HOME/.local/share/applications/synology-office-handler.desktop"
MIME_XML="$HOME/.local/share/mime/packages/x-synology-office.xml"
ICONS="$HOME/.local/share/icons/hicolor/scalable/mimetypes"

[ -x "$BIN" ] && ok "lanceur installe" || ko "lanceur manquant"
grep -qF "Exec=$BIN %f" "$DESKTOP" \
    && ok "Exec absolu dans l'entree desktop" || ko "Exec incorrect"
[ -f "$MIME_XML" ] && ok "types MIME installes" || ko "types MIME manquants"
[ -f "$ICONS/application-x-synology-drive-sheet.svg" ] \
    && ok "icone sheet installee" || ko "icone sheet manquante"
[ -f "$ICONS/application-x-synology-drive-doc.svg" ] \
    && ok "icone doc installee" || ko "icone doc manquante"
[ -f "$ICONS/application-x-synology-drive-slide.svg" ] \
    && ok "icone slide installee (renommee depuis slides.svg)" \
    || ko "icone slide manquante"
[ ! -e "$ICONS/application-x-synology-drive-slides.svg" ] \
    && ok "pas d'icone orpheline slides.svg" \
    || ko "icone orpheline slides.svg presente"
grep -q "synology-office-handler.desktop" "$HOME/.config/mimeapps.list" \
    && ok "associations par defaut enregistrees" \
    || ko "associations par defaut absentes"

# 4. uninstall.sh : retrait complet et symetrique
attend_un_succes "uninstall.sh" "$PROJECT_DIR/uninstall.sh"
[ ! -e "$BIN" ] && ok "lanceur retire" || ko "lanceur encore present"
[ ! -e "$DESKTOP" ] && ok "entree desktop retiree" || ko "entree desktop encore presente"
[ ! -e "$MIME_XML" ] && ok "types MIME retires" || ko "types MIME encore presents"
if ls "$ICONS"/application-x-synology-drive-*.svg >/dev/null 2>&1; then
    ko "icones residuelles : $(ls "$ICONS"/application-x-synology-drive-*.svg)"
else
    ok "icones toutes retirees (aucune residuelle)"
fi

echo ""
echo "Resultat : $PASS ok, $FAIL ko"
[ "$FAIL" -eq 0 ]
