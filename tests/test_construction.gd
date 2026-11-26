extends GutTest

var w: VoxelWorld


func before_each() -> void:
	w = VoxelWorld.new(Vector3i(32, 32, 32))
	for x in 32:
		for z in 32:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))


func test_rayon_touche_le_sol_et_la_face() -> void:
	var r := VoxelRaycast.cast(w, Vector3(5.5, 10, 5.5), Vector3.DOWN)
	assert_true(r["hit"])
	assert_eq(r["pos"], Vector3i(5, 0, 5))
	assert_eq(r["normal"], Vector3i.UP)


func test_rayon_oblique_face_laterale() -> void:
	w.set_raw(Vector3i(10, 1, 5), w.types.num("stone"))
	var r := VoxelRaycast.cast(w, Vector3(2.5, 1.5, 5.5), Vector3.RIGHT)
	assert_eq(r["pos"], Vector3i(10, 1, 5))
	assert_eq(r["normal"], Vector3i.LEFT)


func test_curseur_d_etage_ignore_le_haut() -> void:
	w.set_raw(Vector3i(5, 5, 5), w.types.num("stone"))
	var r := VoxelRaycast.cast(w, Vector3(5.5, 10, 5.5), Vector3.DOWN, 50.0, 4)
	assert_eq(r["pos"], Vector3i(5, 0, 5))


func test_formes() -> void:
	assert_eq(Shapes.line(Vector3i(0, 1, 0), Vector3i(4, 1, 0)).size(), 5)
	assert_eq(Shapes.rect(Vector3i(0, 1, 0), Vector3i(2, 1, 3)).size(), 12)
	assert_eq(Shapes.wall(Vector3i(0, 1, 0), Vector3i(3, 1, 0), 3).size(), 12)
	assert_eq(Shapes.dig_box(Vector3i(5, 10, 5), 2, 3, 4).size(), 24)


func test_annuler_retablir() -> void:
	var h := EditHistory.new(w)
	var plank := w.types.num("plank_block")
	assert_eq(h.apply(Shapes.line(Vector3i(0, 1, 0), Vector3i(4, 1, 0)), plank), 5)
	assert_eq(w.get_block(Vector3i(2, 1, 0)), plank)
	assert_true(h.undo())
	assert_eq(w.get_block(Vector3i(2, 1, 0)), 0)
	assert_true(h.redo())
	assert_eq(w.get_block(Vector3i(2, 1, 0)), plank)


func test_pas_de_pose_dans_un_bloc_plein_ni_effacer_le_socle() -> void:
	var h := EditHistory.new(w)
	assert_eq(h.apply([Vector3i(1, 0, 1)], w.types.num("plank_block")), 0)
	w.set_raw(Vector3i(3, 0, 3), w.types.num("bedrock"))
	assert_eq(h.apply([Vector3i(3, 0, 3)], 0, false), 0)


## Critère J2 : une tour creuse de 10 blocs avec escalier intérieur, sans erreur de pose.
func test_tour_creuse_avec_escalier() -> void:
	var h := EditHistory.new(w)
	var stone := w.types.num("cut_stone_block")
	var placed := 0
	for side: Array in [
		[Vector3i(10, 1, 10), Vector3i(14, 1, 10)],
		[Vector3i(14, 1, 10), Vector3i(14, 1, 14)],
		[Vector3i(14, 1, 14), Vector3i(10, 1, 14)],
		[Vector3i(10, 1, 14), Vector3i(10, 1, 10)]
	]:
		placed += h.apply(Shapes.wall(side[0], side[1], 10), stone)
	assert_eq(placed, 16 * 10, "4 murs de 5 = 16 cases par étage")
	for i in 9:  # escalier qui tourne à l'intérieur
		var ring := [
			Vector3i(11, 0, 11),
			Vector3i(12, 0, 11),
			Vector3i(13, 0, 11),
			Vector3i(13, 0, 12),
			Vector3i(13, 0, 13),
			Vector3i(12, 0, 13),
			Vector3i(11, 0, 13),
			Vector3i(11, 0, 12)
		]
		h.apply([ring[i % 8] + Vector3i(0, i + 1, 0)], stone)
	assert_eq(w.get_block(Vector3i(12, 10, 10)), stone)
	assert_eq(w.get_block(Vector3i(12, 5, 12)), 0, "la tour est creuse au centre")
