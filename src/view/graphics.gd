class_name Graphics
extends RefCounted
## Applique les réglages graphiques du joueur (Paramètres › Graphismes) à la fenêtre, au soleil et au brouillard.


static func apply(vp: Viewport, sky: SkyLight = null) -> void:
	var cfg := DataRegistry.get_table("graphics")
	vp.scaling_3d_scale = clampf(float(Settings.get_value("render_scale")), 0.4, 1.0)
	match str(Settings.get_value("aa")):
		"fxaa":
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		"msaa2":
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	Engine.max_fps = int(Settings.get_value("fps_cap"))
	if sky == null:
		return
	var sh := str(Settings.get_value("shadows"))
	sky.sun.shadow_enabled = sh != "off"
	if sh != "off":
		RenderingServer.directional_shadow_atlas_set_size(int(cfg.get("shadow_sizes", {}).get(sh, 2048)), true)
		sky.sun.directional_shadow_max_distance = float(cfg.get("shadow_distance", {}).get(sh, 100))
	sky.env.fog_enabled = bool(Settings.get_value("fog"))


static func view_distance() -> float:
	return float(Settings.get_value("view_distance"))
