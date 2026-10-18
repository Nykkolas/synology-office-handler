# synology-office-handler

Ouvre les fichiers Synology Office (`.osheet`, `.odoc`, `.oslides`)
synchronises localement par le client Synology Drive dans l'editeur web
Synology Office du NAS, directement depuis un double-clic dans le
gestionnaire de fichiers de Linux Mint (Nemo).

Sous Windows et macOS, c'est le client Synology Drive qui enregistre
cette association ; le client Linux ne le fait pas. Ce projet ne recode
pas la mecanique : il se contente d'enregistrer les types MIME et de
deleguer l'ouverture au client Drive lui-meme.

```
double-clic .osheet
   -> xdg-mime -> synology-office-handler.desktop
   -> syno-office-open (lanceur bash, aucune configuration)
   -> cloud-drive-ui --open-file   (client Synology Drive deja connecte)
   -> le client resout le fichier et ouvre l'editeur dans le navigateur
```

## Prerequis

- Synology Drive Client installe et connecte :
  - Flatpak : `com.synology.SynologyDrive` (teste avec la 4.2.0) ;
  - ou paquet .deb/.rpm : application dans `~/.SynologyDrive/SynologyDrive.app`.
- `xdg-utils` (fournit `xdg-mime`).

Aucun identifiant n'est stocke ni saisi : le client Drive gere seul
l'authentification avec sa session existante, y compris la 2FA.

## Installation

```
./install.sh
```

Puis testez en ligne de commande :

```
~/.local/bin/syno-office-open "/chemin/local/Feuille.osheet"
```

Le double-clic dans Nemo ouvre ensuite l'editeur dans le navigateur.

## Details techniques

- Le lanceur verifie l'extension du fichier et la presence du client,
  puis appelle `cloud-drive-ui --open-file` tel que le fait
  l'integration officielle Windows/macOS.
- Sous Flatpak, l'appel transite par le bac a sable
  (`flatpak run --command=sh com.synology.SynologyDrive ...`) : un appel
  direct depuis l'hote echoue (l'UI ne rejoint pas son daemon).
- `install.sh` recupere au passage les icones SVG officielles du client
  (`application-x-synology-drive-*.svg`) pour l'affichage dans Nemo ;
  elles sont supprimees par `uninstall.sh`.
- Les types MIME declares reprennent les noms officiels utilises par
  Synology (`application/x-synology-drive-sheet`, etc.), identiques a
  ceux embarques dans le client (`~/.SynologyDrive/SynologyDrive.app/conf/`).
- En cas d'erreur (client absent, fichier introuvable), une notification
  bureau est affichee et le code retour est non nul. Si le fichier n'est
  dans aucun dossier synchronise, c'est le client Drive qui affiche sa
  propre erreur.

## Desinstallation

```
./uninstall.sh
```
