class_name HexRenderer
extends Node2D

var hex_grid: HexGrid
var hex_color: Color = Color.LIGHT_BLUE
var outline_color: Color = Color.WHITE

func setup(grid: HexGrid):
	hex_grid = grid
	queue_redraw()

func _draw():
	if not hex_grid:
		return
		
	for hex_coord in hex_grid.get_all_hexes():
		var hex_tile = hex_grid.get_hex(hex_coord)
		draw_hex(hex_tile.world_pos, hex_grid.hex_size)

func draw_hex(center: Vector2, size: float):
	var points = get_hex_points(center, size)
	draw_colored_polygon(points, hex_color)
	
	for i in range(6):
		var start = points[i]
		var end = points[(i + 1) % 6]
		draw_line(start, end, outline_color, 2.0)

func get_hex_points(center: Vector2, size: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60 * i)  # Changed from (60 * i - 30)
		var point = center + Vector2(cos(angle), sin(angle)) * size
		points.append(point)
	return points
