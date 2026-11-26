class_name ItemsView
extends Node3D
## Piles d'objets au sol (bûches, pierres, viande…) : un petit tas par case, couleur selon la ressource.

const COLORS := {
	"log": "6a4a2e",
	"stone": "8a8a88",
	"dirt": "6a503a",
	"meat": "a04a3c",
	"hide": "9a7a58",
	"fish": "8aa0b0",
	"berries": "8c2038",
	"flax": "c8b878",
	"sand": "c8b88a",
	"clay": "a07060",
	"coal": "2a2a2c",
	"iron_ore": "a07a60"
}

var _ground: GroundItems
var _nodes: Dictionary = {}


func bind(g: GroundItems) -> void:
	_ground = g
	g.changed.connect(_update)
	for c: Vector3i in g.piles:
		_update(c)


func _update(cell: Vector3i) -> void:
	if _nodes.has(cell):
		_nodes[cell].queue_free()
		_nodes.erase(cell)
	var pile: Dictionary = _ground.piles.get(cell, {})
	if pile.is_empty():
		return
	var root := Node3D.new()
	root.position = Vector3(cell) + Vector3(0.5, 0, 0.5)
	var i := 0
	for id: String in pile:
		for k in mini(int(pile[id]), 4):
			var mi := MeshInstance3D.new()
			if id == "log":
				var c := CylinderMesh.new()
				c.top_radius = 0.09
				c.bottom_radius = 0.09
				c.height = 0.6
				c.radial_segments = 6
				mi.mesh = c
				mi.rotation = Vector3(0, 0, PI / 2)
			else:
				var b := BoxMesh.new()
				b.size = Vector3(0.22, 0.16, 0.22)
				mi.mesh = b
			mi.material_override = LutinModel.mat(COLORS.get(id, "8a7a60"), 0.85)
			mi.position = Vector3(-0.2 + (i % 3) * 0.2, 0.09 + (i / 3) * 0.17, -0.15 + (k % 2) * 0.3)
			root.add_child(mi)
			i += 1
	add_child(root)
	_nodes[cell] = root
