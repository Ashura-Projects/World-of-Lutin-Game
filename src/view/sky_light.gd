class_name SkyLight
extends Node3D
## Soleil, ciel, brume : suivent l'heure du jour (data/lighting.json).

var sun: DirectionalLight3D
var env: Environment
var _cfg: Dictionary


func _ready() -> void:
	_cfg = DataRegistry.get_table("lighting")
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = float(_cfg.get("ambient_energy", 0.55))
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.fog_enabled = true
	env.fog_density = float(_cfg.get("fog_density", 0.006))
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	update(0.4)


func _c(key: String) -> Color:
	return Color(str(_cfg.get(key, "ffffff")))


## tod = heure du jour (0..1) ; midi = 0.5.
func update(tod: float) -> void:
	var t := DataRegistry.get_table("time")
	var dawn := float(t.get("dawn", 0.25))
	var dusk_t := float(t.get("dusk", 0.8))
	var span := dusk_t - dawn
	var k := clampf((tod - dawn) / span, 0.0, 1.0)  # 0 à l'aube, 1 au crépuscule
	var day_f := clampf(sin(k * PI) * 2.5, 0.0, 1.0)
	var dusk := clampf(1.0 - sin(k * PI) * 3.0, 0.0, 1.0) * day_f
	# le soleil va de l'est à l'ouest, élévation max ~ 55°
	sun.rotation = Vector3(-deg_to_rad(10.0 + 45.0 * sin(k * PI)), deg_to_rad(-60.0 + 120.0 * k), 0)
	sun.light_color = _c("sun_day").lerp(_c("sun_dusk"), dusk)
	sun.light_energy = lerpf(float(_cfg.get("sun_energy_night", 0.08)), float(_cfg.get("sun_energy_day", 1.25)), day_f)
	var sky := _c("sky_night").lerp(_c("sky_day"), day_f).lerp(_c("sky_dusk"), dusk * 0.6)
	env.background_color = sky
	env.ambient_light_color = sky.lerp(Color.WHITE, 0.3)
	env.ambient_light_energy = lerpf(0.25, float(_cfg.get("ambient_energy", 0.55)), day_f)
	env.fog_light_color = sky
