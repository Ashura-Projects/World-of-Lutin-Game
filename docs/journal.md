# Journal du marathon (Bac à sable J0 → J8)

Reprise : lire ce fichier, puis `prompts/03-reprise-et-corrections.md`.

| Jalon | État | Preuves |
|---|---|---|
| J0 — Fondations | en cours | |
| J1 — Le monde en blocs | à faire | |
| J2 — Construire au doigt | à faire | |
| J3 — Les Lutins | à faire | |
| J4 — Récolte & métiers | à faire | |
| J5 — Les lutins bâtissent | à faire | |
| J6 — Agriculture & production | à faire | |
| J7 — Prédateurs, gestion & sauvegarde | à faire | |
| J8 — Familles, école & recherche | à faire | |

## J0 — Fondations
Plan : projet Godot 4.7.2 (rendu Mobile, paysage 20:9), autoloads (EventBus, DataRegistry, Rng, GameClock, SaveManager,
Settings, GameSetup), GUT 9.7.1 headless, export Android arm64 (`com.ashura.worldoflutin`), workflow GitHub Actions
(tests puis APK, publication `dernier-build` sur main), écran titre au style validé avec configuration de partie (2-10 lutins, graine).

## Choix faits sans Ashura
- Godot **4.7.2** (dernière 4.7.x stable avec image godot-ci identique).
- Nom de paquet Android : `com.ashura.worldoflutin`.
- GUT récupéré via le CDN jsDelivr (les archives GitHub d'autres dépôts sont bloquées dans l'environnement cloud).
- Chariot de départ : 6 peaux (2 tentes), le reste par la chasse.
- Carte par défaut 256×256×64 ; si la perf ne tient pas sur le Xiaomi, 128×128 par défaut (mesure au J1).

## Problèmes connus
- Le travail est poussé sur la branche de session `ccr-a284deb7-1npond` ; la fusion dans `main` (qui publie l'APK) attend l'accord d'Ashura.
