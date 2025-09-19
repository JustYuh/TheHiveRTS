class_name HexTile
extends RefCounted

var hex_coord: Vector2
var world_pos: Vector2

func _init(coord: Vector2, world_position: Vector2):
	hex_coord = coord
	world_pos = world_position

func get_info() -> String:
	return "Hex (%d,%d)" % [hex_coord.x, hex_coord.y]
