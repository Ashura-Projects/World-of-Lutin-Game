# 04 — Architecture technique

## Arborescence
```
data/                 # JSON : blocs, ressources, recettes, métiers, pièces, objets
assets/  (+ CREDITS.md obligatoire : source + licence de chaque asset)
src/
  autoload/           # GameClock, EventBus, DataRegistry, SaveManager, Rng, Settings
  sim/                # logique pure, sans nœud de scène
    voxel/            # VoxelWorld, Chunk (PackedByteArray 16³), BlockTypes, WorldGenerator
    nav/              # NavGrid 3D, pathfinding, mise à jour incrémentale
    rooms/            # RoomDetector (remplissage 3D), RoomTypes
    lutins/           # Lutin, Needs, Job/Tool, Experience
    tasks/            # TaskBoard, Task, Reservation, TaskGivers (haul, build, dig, cut, craft…)
    economy/          # Stockpile, ItemStack, Workstation, ProductionOrder
    construction/     # Blueprint, BuildQueue, StabilityRule
    farming/          # Field, Crop, Seasons
    [phase 2] combat/ siege/ region/ diplomacy/
  view/               # ChunkMesher (thread), ChunkView, LutinView, PreviewView, fx
  input/              # CameraController, gestes, outils (BlockTool, ZoneTool, LayerSlicer)
  ui/
tests/                # GUT : un test_*.gd par système
```

## Le monde en blocs
- `VoxelWorld` = dictionnaire de chunks 16×16×16 ; un bloc = 1 octet (id de type). Métadonnées rares (orientation, plan) dans un dictionnaire à part.
- `ChunkMesher` : faces visibles seulement, **fusion des faces** (greedy meshing), UV dans un **atlas** unique ; tourne sur `WorkerThreadPool`, résultat appliqué dans le thread principal.
- Modification d'un bloc → chunk (et voisins si bord) marqués sales → remaillage en file avec budget par image.
- Collisions et clic : **lancer de rayon voxel** (algorithme DDA) sur la grille, pas de physique Godot → donne le bloc ET la face touchée (pose « à la Minecraft »).

## Navigation 3D
- Case marchable = air, bloc solide dessous, air au-dessus (lutin = 1 bloc de haut).
- Liens : voisins à même hauteur, ±1 bloc (marche), échelle (vertical), escalier.
- A* sur ces cases + **régions par chunk** pour savoir vite si un point est atteignable. Mise à jour locale à chaque bloc modifié.
- Budget : max N recherches de chemin par tick, cache des chemins fréquents (réserve ↔ chantier).

## Boucle de simulation (ordre fixe par tick)
Temps/saisons → besoins → attribution des tâches → déplacements/exécution → construction → production → croissance (cultures, arbres) → événements.

## Tâches
- `TaskBoard` centralise les tâches ; un lutin libre prend la meilleure selon **son outil/métier**, la distance et la priorité.
- **Réservations** : une cible = un seul lutin. Tâche impossible → quarantaine quelques secondes.

## Sauvegarde
- Chunks compressés (RLE puis `FileAccess.open_compressed`), état sim en JSON versionné, dans `user://saves/`.
- Sauvegarde auto toutes les 5 min et à la mise en arrière-plan de l'appli.
