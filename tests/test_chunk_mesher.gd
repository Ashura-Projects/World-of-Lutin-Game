extends GutTest


func test_un_bloc_six_faces() -> void:
	var w := VoxelWorld.new(Vector3i(32, 32, 32))
	w.set_raw(Vector3i(4, 4, 4), w.types.num("stone"))
	var r := ChunkMesher.build(w, Vector3i.ZERO)
	assert_eq(r["faces"], 6)
	assert_eq(r["opaque"][Mesh.ARRAY_INDEX].size(), 36)


func test_faces_cachees_supprimees() -> void:
	var w := VoxelWorld.new(Vector3i(32, 32, 32))
	w.set_raw(Vector3i(4, 4, 4), w.types.num("stone"))
	w.set_raw(Vector3i(5, 4, 4), w.types.num("stone"))
	assert_eq(ChunkMesher.build(w, Vector3i.ZERO)["faces"], 10)


func test_faces_entre_chunks() -> void:
	var w := VoxelWorld.new(Vector3i(32, 32, 32))
	w.set_raw(Vector3i(15, 4, 4), w.types.num("stone"))
	w.set_raw(Vector3i(16, 4, 4), w.types.num("stone"))
	var a: int = ChunkMesher.build(w, Vector3i(0, 0, 0))["faces"]
	var b: int = ChunkMesher.build(w, Vector3i(1, 0, 0))["faces"]
	assert_eq(a + b, 10)


func test_eau_separee_et_curseur_d_etage() -> void:
	var w := VoxelWorld.new(Vector3i(32, 32, 32))
	w.set_raw(Vector3i(2, 2, 2), w.types.num("water"))
	w.set_raw(Vector3i(2, 6, 2), w.types.num("stone"))
	var r := ChunkMesher.build(w, Vector3i.ZERO)
	assert_false(r["liquid"].is_empty())
	var cut := ChunkMesher.build(w, Vector3i.ZERO, 5)
	assert_eq(cut["faces"], 6, "le bloc au-dessus de l'étage est masqué")
