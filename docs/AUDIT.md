# AUDIT.md - Grille d'audit du code

<!--
Modèle créé par init-preferences.sh. Il ne remplace jamais un AUDIT.md existant.
La procédure, les sévérités, les thèmes génériques et le format du rapport sont
dans docs/AUDIT-GENERIC.md (agents-shared). Ce fichier ne contient que la
checklist SPÉCIFIQUE au projet.
-->

Procédure à suivre quand l'utilisateur demande un audit / une review du code :
suivre `docs/AUDIT-GENERIC.md`, puis passer la checklist spécifique ci-dessous.
L'audit ne modifie **aucun fichier**.

## 🎯 Checklist spécifique à ce projet

Sécurité :
- [ ] Aucun identifiant, token ou URL NAS n'est stocké ni loggé (le lanceur délègue, il n'authentifie pas).
- [ ] Aucune injection possible via le nom de fichier (espaces, guillemets, métacaractères) dans les appels `flatpak run` / `exec` et le sed de `install.sh`.
- [ ] Aucune exécution de commande construite à partir du nom de fichier sans quoting correct.

Opérations fichiers :
- [ ] `install.sh` et `uninstall.sh` n'écrivent/suppriment que dans `~/.local/...` ; rien hors du répertoire utilisateur.
- [ ] `uninstall.sh` supprime exactement ce que `install.sh` a posé (symétrie), sans toucher aux fichiers du client Drive hormis les icônes copiées.
- [ ] `rm -f` ciblés uniquement, jamais de suppression récursive ou de motif large non borné.

Cas limites du domaine :
- [ ] Fichier absent, extension non gérée, majuscules d'extension (`.OSHEET`) : message clair et code retour non nul.
- [ ] Client Drive absent ou non exécutable : notification bureau + message explicite, pas de traceback brut.
- [ ] Fichier dans un dossier non synchronisé : comportement du client Drive acceptable (erreur de sa part, pas du lanceur).
- [ ] Chemins avec espaces ou caractères unicode valides sur toute la chaîne (desktop `%f` -> lanceur -> flatpak -> UI).
- [ ] `realpath` sur un chemin relatif et sur un lien symbolique : le fichier résolu est bien celui passé au client.

Portabilité / environnement :
- [ ] `set -euo pipefail` respecté dans les trois scripts ; aucune commande pouvant échouer silencieusement en cassant le script.
- [ ] Comportement identique Flatpak installé système (`/var/lib/flatpak`) vs utilisateur (`~/.local/share/flatpak`).
- [ ] `notify-send` absent : dégradation silencieuse, pas d'échec du lanceur.

## 📄 Format du rapport

Voir `docs/AUDIT-GENERIC.md` : tableau unique trié par sévérité, conclusion
d'une à trois phrases.
