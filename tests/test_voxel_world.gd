extends GutTest


func test_chunk_lecture_ecriture() -> void:
	var c := Chunk.new()
	c.set_local(1, 2, 3, 7)
	assert_eq(c.get_local(1, 2, 3), 7)
	assert_eq(c.solid_count, 1)
	c.set_local(1, 2, 3, 0)
	assert_true(c.is_empty())


func test_chunk_rle_aller_retour() -> void:
	var c := Chunk.new()
	for i in 500:
		c.set_local(i % 16, (i / 16) % 16, i % 7, (i % 5) + 1)
	var c2 := Chunk.new()
	c2.from_rle(c.to_rle())
	assert_eq(c2.data, c.data)


func test_monde_signal_et_limites() -> void:
	var w := VoxelWorld.new(Vector3i(32, 32, 32))
	watch_signals(w)
	assert_true(w.set_block(Vector3i(5, 5, 5), 7))
	assert_signal_emitted(w, "block_changed")
	assert_eq(w.get_block(Vector3i(5, 5, 5)), 7)
	assert_false(w.set_block(Vector3i(-1, 0, 0), 7))
	assert_eq(w.get_block(Vector3i(99, 0, 0)), 0)


func test_monde_aller_retour_sauvegarde() -> void:
	var w := VoxelWorld.new(Vector3i(48, 32, 48))
	for i in 300:
		w.set_raw(Vector3i(i % 48, i % 20, (i * 7) % 48), 1 + i % 9)
	var w2 := VoxelWorld.new()
	w2.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	assert_eq(w2.size, w.size)
	for i in 300:
		var p := Vector3i(i % 48, i % 20, (i * 7) % 48)
		assert_eq(w2.get_block(p), w.get_block(p))


func test_chunks_touches_au_bord() -> void:
	assert_eq(VoxelWorld.affected_chunks(Vector3i(5, 5, 5)).size(), 1)
	assert_eq(VoxelWorld.affected_chunks(Vector3i(15, 5, 5)).size(), 2)
