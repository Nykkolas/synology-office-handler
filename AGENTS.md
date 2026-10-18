# AGENTS.md - Règles et meilleures pratiques pour ce projet

## 🤝 Mode de collaboration

### Commits et push
- Ne jamais commiter ni pousser sans l'**autorisation explicite** de l'utilisateur : proposer, attendre le oui.

### "Propose-moi" = proposer, ne pas exécuter
- Quand l'utilisateur demande de **proposer** (améliorations, changements, refactor), NE PAS modifier les fichiers.
- Expliquer d'abord ce qui est prévu : fichiers concernés, commandes à exécuter, risques.
- Attendre l'**autorisation explicite** de l'utilisateur avant d'appliquer quoi que ce soit.
- Les demandes directes ("fais", "corrige", "ajoute") restent des autorisations à agir immédiatement.

### "Audit / review du code"
- Lire `docs/AUDIT.md` (checklist spécifique) et `docs/AUDIT-GENERIC.md` (procédure, thèmes, sévérités, format de rapport).
- L'audit ne modifie aucun fichier : recommandations uniquement, sauf demande explicite de corriger.

### "Crée une version x.y.z"
- Équivaut à : `git tag vx.y.z` + `git push origin vx.y.z` (autorisation explicite incluse).
- Ce projet n'a pas de CI : le tag n'agit que comme repère de version. Après le push, vérifier que le tag est bien présent sur le remote (`git ls-remote --tags origin`).

## 🌍 Langue

- **Code en anglais** : identifiants, fonctions, modules, messages, noms de tests.
- **UI en français** : libellés, statuts, messages affichés à l'utilisateur.
- La documentation (AGENTS.md, AUDIT.md, TODO.md, README) est en français.

## 📚 Règles partagées (agents-shared, à lire selon le contexte)

Ces fichiers sont des symlinks vers `~/Source/agents-shared/` :

- **Audit générique** : `docs/AUDIT-GENERIC.md`, complété par la checklist locale `docs/AUDIT.md`.
- **Erreurs transverses** : `docs/ERREURS-GENERIC.md`, leçons génériques à ne pas reproduire.

## 🏛️ Architecture

Petit projet sans build, installé uniquement dans les répertoires
utilisateur (`~/.local/...`). Suite de tests automatisés : `./test.sh`,
à relancer avant tout commit. Chaîne d'ouverture :

```
double-clic .osheet
   -> xdg-mime -> synology-office-handler.desktop
   -> syno-office-open (lanceur bash, aucune configuration)
   -> cloud-drive-ui --open-file (client Synology Drive déjà connecté)
```

- `syno-office-open` : lanceur, vérifie le fichier et l'extension, détecte
  l'installation Flatpak ou paquet du client Drive, puis délègue via
  `--open-file`. Ne stocke aucun identifiant, n'interroge aucune API.
- `install.sh` / `uninstall.sh` : (dés)installation dans `~/.local`
  uniquement ; symétriques l'un de l'autre.
- `x-synology-office.xml` : types MIME officiels Synology
  (`application/x-synology-drive-{sheet,doc,slide}`).
- `synology-office-handler.desktop` : entrée desktop associée aux types MIME.

Frontières à respecter : le lanceur ne fait que vérifier puis déléguer ;
toute la résolution et l'authentification restent au client Drive.

## Bonnes pratiques générales

### TDD
- Approche par défaut pour les corrections et nouvelles fonctionnalités : écrire d'abord le test qui échoue, le voir échouer, puis corriger le code, puis revérifier (rouge/vert).
- Chaque bug corrigé doit avoir son test de non-régression.
- Si la zone modifiée n'est couverte par aucun test automatisé, exiger au
  minimum une reproduction manuelle documentée (commande exacte,
  comportement attendu vs observé) avant/après la correction.

### DRY
- Éviter la répétition de code. Extraire les conditions répétées en fonctions helpers.

### Strings magiques
- Éviter les strings littérales dans le code. Préférer des constantes ou des types dédiés.

### Nommage
- **Messages** : des noms explicites (`...Requested`, `...Finished`, `...Failed`).
- **State** : des noms clairs (`IsBusy`, `Status`).
- **Fonctions** : des verbes (`findPairs`, `copyText`).

## ❌ Erreurs à ne pas reproduire

- Icônes de types MIME et thème GTK : leçon générique dans
  `docs/ERREURS-GENERIC.md` (lookup_by_gicon préfère, à distance égale,
  le nom trouvé dans le thème actif à celui trouvé dans hicolor).
  Spécifique au projet : `install.sh` pose les SVG+PNG dans hicolor et
  le thème actif détecté via gsettings — couvert par `test.sh`.
- Icônes du client Drive vs types MIME : le client embarque
  `slides.svg` mais le type MIME officiel est `x-synology-drive-slide`
  (sans « s »). Normaliser le nom à l'installation et garder install /
  uninstall symétriques (même glob) — couvert par `test.sh`.
- Ne pas appeler `cloud-drive-ui` directement depuis l'hôte quand le client
  est installé en Flatpak : l'appel échoue (code 255) car l'UI ne rejoint pas
  son daemon. Passer par `flatpak run --command=sh com.synology.SynologyDrive ...`.
- Ne pas inventer de types MIME : garder les noms officiels embarqués dans le
  client (`application/x-synology-drive-*`), sinon l'association officielle
  peut rentrer en conflit.
- Sous Flatpak, définir `LD_LIBRARY_PATH` vers les libs du client
  (`~/.SynologyDrive/SynologyDrive.app/lib/`) est nécessaire au lancement de
  l'UI ; l'omettre fait échouer le binaire.
- Les chemins de fichiers contenant des espaces doivent rester valides à
  travers toute la chaîne (desktop entry `%f` -> lanceur -> flatpak -> UI).
