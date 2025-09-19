# HexRenderer.gd
# Pure visual rendering system for hex grid - no UI management
class_name HexRenderer
extends Node2D

# Reference to the hex grid data
var hex_grid: HexGrid

# Rendering settings
@export var hex_size: float = 35.0
@export var outline_width: float = 2.0
@export var show_coordinates: bool = false

# Visual settings for resources
@export var resource_pulse_speed: float = 2.0
@export var rare_resource_glow: bool = true

# Performance optimization
var visible_hexes: Array = []
var time_passed: float = 0.0

func _ready():
	pass

func setup(p_hex_grid: HexGrid):
	hex_grid = p_hex_grid
	print("HexRenderer: Setup complete - pure rendering mode")

func _draw():
	if not hex_grid:
		return
	
	# Draw all hexes with resource-based coloring
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		_draw_hex_tile(hex_tile)

func _draw_hex_tile(hex_tile: HexTile):
	var world_pos = hex_tile.world_position
	var display_color = hex_tile.get_display_color()
	
	# Create hexagon points
	var points = _get_hex_points(world_pos)
	
	# Draw filled hexagon with resource color
	draw_colored_polygon(points, display_color)
	
	# Draw outline
	var outline_color = Color.WHITE
	if hex_tile.has_resource:
		# Different outline colors for different resource rarities
		var resource = hex_tile.get_resource()
		if resource.rarity < 0.05:  # Super rare
			outline_color = Color.YELLOW
		elif resource.rarity < 0.1:  # Rare
			outline_color = Color.ORANGE
	
	_draw_hex_outline(points, outline_color)
	
	# Draw resource-specific visual effects
	if hex_tile.has_resource:
		_draw_resource_effects(hex_tile)
	
	# Debug information
	if show_coordinates:
		_draw_coordinate_text(hex_tile)

func _draw_resource_effects(hex_tile: HexTile):
	var resource = hex_tile.get_resource()
	if not resource:
		return
	
	# Pulsing effect for high-value resources
	if resource.rarity < 0.1:  # Rare resources pulse
		var pulse_alpha = 0.3 + sin(time_passed * resource_pulse_speed) * 0.2
		var pulse_color = resource.color
		pulse_color.a = pulse_alpha
		
		var points = _get_hex_points(hex_tile.world_position, hex_size * 0.8)
		draw_colored_polygon(points, pulse_color)
	
	# Crystal formations get special sparkle effect
	if resource.type == ResourceType.Type.CRYSTAL:
		_draw_crystal_sparkles(hex_tile)
	
	# Chemical soup gets bubbling effect
	if resource.type == ResourceType.Type.CHEMICAL:
		_draw_chemical_bubbles(hex_tile)

func _draw_crystal_sparkles(hex_tile: HexTile):
	# Simple sparkle effect with small dots
	var center = hex_tile.world_position
	var sparkle_count = 3
	
	for i in range(sparkle_count):
		var angle = (time_passed + i) * 2.0
		var offset = Vector2(cos(angle), sin(angle)) * hex_size * 0.3
		var sparkle_pos = center + offset
		
		draw_circle(sparkle_pos, 2.0, Color.WHITE)

func _draw_chemical_bubbles(hex_tile: HexTile):
	# Simple bubble effect
	var center = hex_tile.world_position
	var bubble_count = 2
	
	for i in range(bubble_count):
		var bubble_time = time_passed * 1.5 + i * 2.0
		var y_offset = (sin(bubble_time) * 0.5 + 0.5) * hex_size * 0.6
		var x_offset = cos(bubble_time * 0.3) * hex_size * 0.2
		var bubble_pos = center + Vector2(x_offset, -y_offset)
		
		var bubble_size = 3.0 + sin(bubble_time * 2.0) * 1.0
		draw_circle(bubble_pos, bubble_size, Color(0.8, 1.0, 0.8, 0.6))

func _draw_hex_outline(points: PackedVector2Array, color: Color):
	for i in range(points.size()):
		var start_point = points[i]
		var end_point = points[(i + 1) % points.size()]
		draw_line(start_point, end_point, color, outline_width)

func _draw_coordinate_text(hex_tile: HexTile):
	var text = "(%d,%d)" % [hex_tile.hex_coord.x, hex_tile.hex_coord.y]
	var font = ThemeDB.fallback_font
	var font_size = 12
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = hex_tile.world_position - text_size / 2
	
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)

func _get_hex_points(center: Vector2, size: float = 0.0) -> PackedVector2Array:
	if size == 0.0:
		size = hex_size
	
	var points = PackedVector2Array()
	
	# Generate 6 points for flat-top hexagon
	for i in range(6):
		var angle = (i * PI) / 3.0  # 60 degrees apart
		var point = center + Vector2(cos(angle), sin(angle)) * size
		points.append(point)
	
	return points

func _process(delta):
	time_passed += delta
	
	# Redraw for animated effects (only if we have resources that need animation)
	if _has_animated_resources():
		queue_redraw()

func _has_animated_resources() -> bool:
	if not hex_grid:
		return false
	
	# Check if any hex has rare resources that need animation
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		if hex_tile.has_resource:
			var resource = hex_tile.get_resource()
			if resource.type == ResourceType.Type.CRYSTAL or resource.type == ResourceType.Type.CHEMICAL:
				return true
	
	return false

# Public function to update display settings
func set_display_mode(coordinates: bool):
	show_coordinates = coordinates
	queue_redraw()

# Get resource at world position (for external systems)
func get_resource_at_position(world_pos: Vector2) -> HexTile:
	if not hex_grid:
		return null
	
	# Find closest hex to click position
	var closest_hex = null
	var closest_distance = INF
	
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		var distance = world_pos.distance_to(hex_tile.world_position)
		
		if distance < closest_distance and distance < hex_size:
			closest_distance = distance
			closest_hex = hex_tile
	
	return closest_hex
