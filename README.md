# World of Lutin

Jeu mobile Android de construction en blocs, gestion et stratégie médiéval-fantastique.
L'esprit de *Castle Story*, amélioré : économie, métiers, agriculture, saisons, puis royaume, guerres et diplomatie.

- **Phase 1 — Bac à sable** : terre ferme (rivière, forêt, montagne), récolte, construction bloc par bloc au doigt, métiers, agriculture. Pas d'ennemis.
- **Phase 2 — Aventure Royale** : quelques lutins au départ, bâtir un royaume, Orcs, sièges, diplomatie, conquête.

Projet personnel d'**Ashura**, développé dans le cloud avec Claude Code (Godot 4.7).

## Contenu
| Fichier | Rôle |
|---|---|
| `CLAUDE.md` | Règles que Claude Code suit automatiquement |
| `docs/01-vision.md` | Pitch, modes, piliers |
| `docs/02-conception.md` | Toutes les mécaniques (source de vérité) |
| `docs/03-feuille-de-route.md` | Jalons J0 → J14 avec critères de réussite |
| `docs/04-architecture.md` | Code, moteur de blocs, navigation 3D |
| `docs/05-outils-et-assets.md` | Outils cloud, skills, sources d'assets |
| `docs/06-direction-artistique.md` | Style, Lutins, Orcs, caméra |
| `docs/07-interface-mobile.md` | Gestes, pose de blocs au doigt |
| `docs/decisions/` | Décisions techniques (ADR) |
| `data/*.json` | Blocs, ressources, recettes, métiers, pièces, population, éducation, technologies |
| `prompts/01…03` | Ordre de lancement : planches de style → Bac à sable complet → reprise / corrections |
| `prompts/bibliotheque-prompts.md` | Prompts ponctuels (bug, lag, équilibrage…) |
| `.claude/commands/` | `/jalon`, `/verifier`, `/point` |

## Démarrer
1. Dépôt : `Ashura-Projects/World-of-Lutin-Game` (dossier déjà en place).
2. Ouvrir Claude Code sur ce dépôt.
3. Coller : « Lis prompts/00-passation.md et exécute-le. »
