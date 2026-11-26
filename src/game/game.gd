extends Node3D
## Scène de jeu (J0 : placeholder ; le monde en blocs arrive au J1).


func _ready() -> void:
	Rng.set_seed(GameSetup.seed_value)
	GameClock.reset()
	GameClock.running = true
