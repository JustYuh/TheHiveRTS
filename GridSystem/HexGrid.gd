class_name HexGrid
extends RefCounted

var hex_radius: int = 8
var hex_size: float = 30.0
var grid_data: Dictionary = {}

const HEX_DIRECTIONS = [
	Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
	Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
]

func _init():
	generate_grid()

func generate_grid():
	grid_data.clear()
	
	for q in range(-hex_radius, hex_radius + 1):
		var r1 = max(-hex_radius, -q - hex_radius)
		var r2 = min(hex_radius, -q + hex_radius)
		
		for r in range(r1, r2 + 1):
			var hex_coord = Vector2(q, r)
			if hex_distance(hex_coord, Vector2.ZERO) <= hex_radius:
				var world_pos = axial_to_world(hex_coord)
				var hex_tile = HexTile.new(hex_coord, world_pos)
				grid_data[hex_coord] = hex_tile

func hex_distance(hex_a: Vector2, hex_b: Vector2) -> int:
	var cube_a = axial_to_cube(hex_a)
	var cube_b = axial_to_cube(hex_b)
	return int((abs(cube_a.x - cube_b.x) + abs(cube_a.y - cube_b.y) + abs(cube_a.z - cube_b.z)) / 2)

func axial_to_cube(hex: Vector2) -> Vector3:
	var x = hex.x
	var z = hex.y
	var y = -x - z
	return Vector3(x, y, z)

func axial_to_world(hex: Vector2) -> Vector2:
	var x = hex_size * (3.0/2.0 * hex.x)
	var y = hex_size * (sqrt(3.0)/2.0 * hex.x + sqrt(3.0) * hex.y)
	return Vector2(x, y)

func world_to_axial(world_pos: Vector2) -> Vector2:
	var q = (2.0/3.0 * world_pos.x) / hex_size
	var r = (-1.0/3.0 * world_pos.x + sqrt(3.0)/3.0 * world_pos.y) / hex_size
	return hex_round(Vector2(q, r))

func hex_round(hex: Vector2) -> Vector2:
	var cube = axial_to_cube(hex)
	var rx = round(cube.x)
	var ry = round(cube.y)
	var rz = round(cube.z)
	
	var x_diff = abs(rx - cube.x)
	var y_diff = abs(ry - cube.y)
	var z_diff = abs(rz - cube.z)
	
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	
	return Vector2(rx, rz)

func has_hex(hex_coord: Vector2) -> bool:
	return grid_data.has(hex_coord)

func get_hex(hex_coord: Vector2) -> HexTile:
	return grid_data.get(hex_coord)

func get_all_hexes() -> Array:
	return grid_data.keys()
