extends GutTest

const SIZE := Vector3i(64, 64, 64)


func _gen(seed_value: int) -> WorldGenerator:
	var w := VoxelWorld.new(SIZE)
	var g := WorldGenerator.new(w, seed_value)
	g.generate()
	return g


func test_meme_graine_meme_monde() -> void:
	assert_eq(_gen(42).fingerprint(), _gen(42).fingerprint())


func test_graines_differentes() -> void:
	assert_ne(_gen(1).fingerprint(), _gen(2).fingerprint())


func test_couches() -> void:
	var g := _gen(7)
	var w := g.world
	var t := w.types
	for x in range(0, 64, 9):
		for z in range(0, 64, 9):
			assert_eq(w.get_block(Vector3i(x, 0, z)), t.num("bedrock"), "socle en bas")
			var top := w.surface_y(x, z)
			assert_gt(top, 2)
			var surf := w.get_block(Vector3i(x, top - 1, z))
			assert_true(
				surf in [t.num("grass"), t.num("sand"), t.num("snow"), t.num("stone"), t.num("fertile_soil")],
				"surface %d" % surf
			)


func test_eau_et_arbres() -> void:
	var g := _gen(11)
	var water := 0
	for c: Chunk in g.world.chunks.values():
		for v in c.data:
			if v == g.world.types.num("water"):
				water += 1
	assert_gt(water, 0, "une rivière existe")
	assert_gt(g.trees.size(), 0, "des arbres existent")
