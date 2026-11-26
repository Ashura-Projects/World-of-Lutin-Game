# ADR-001 — Godot 4.7 + moteur de blocs maison en GDScript

- **Statut** : proposé (à valider par Ashura)
- **Date** : 2026-11-26

## Contexte
Jeu de construction en blocs sur téléphone, développé dans le cloud par Claude Code, sans budget.
Les blocs sont gros (1 unité) et la carte modeste (128×128×48) : pas besoin de terrain lisse ni de monde infini.

## Décision
- Godot 4.7.x, GDScript typé, rendu Mobile.
- Moteur de blocs **écrit par nous** : chunks 16³, maillage par fusion de faces sur thread, atlas unique, lancer de rayon voxel.
- Pas de module de voxels externe (il impose souvent de recompiler le moteur, ce qui complique le build cloud).

## Conséquences
- + Build Android standard, contrôle total, code simple et testable.
- + Réutilise les skills Godot déjà en place.
- − Le maillage en GDScript peut être lent : **plan B** = porter uniquement `ChunkMesher` en GDExtension C++ compilée par GitHub Actions (nouvel ADR).
- − Pas d'eau qui coule ni de terrain lisse.

## Modèle pour les prochains ADR
Statut / Date / Contexte / Décision / Conséquences.
