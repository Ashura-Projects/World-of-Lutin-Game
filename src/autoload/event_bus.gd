extends Node
## Bus d'événements global : les systèmes communiquent par signaux, sans se connaître.

@warning_ignore_start("unused_signal")
signal tick(tick_index: int)
signal day_changed(day: int)
signal season_changed(season_index: int)
signal speed_changed(speed: int)
signal block_changed(pos: Vector3i, old_id: int, new_id: int)
signal chunk_dirty(chunk_key: Vector3i)
signal game_saved(slot: String)
signal game_loaded(slot: String)
signal alert(kind: String, text: String)
signal sfx(name: String, pos: Vector3)
signal faction_changed
signal settings_changed  # réglages du joueur modifiés (graphismes, son, jeu)
@warning_ignore_restore("unused_signal")
