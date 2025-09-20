# Building.gd
# Base class for buildings in the RTS game
class_name Building
extends Node2D

# Building properties
var building_name: String = "Basic Building"
var hex_position: Vector2
var construction_complete: bool = true
var health: float = 100.0
var max_health: float = 100.0

# Resource system
var resource_cost: Dictionary = {}
var resource_production: Dictionary = {}
var collection_timer: float = 0.0
var collection_interval: float = 3.0  # Collect every 3 seconds
var hex_grid: HexGrid
var building_manager: Node

# Signals
signal resource_collected(resource_type: String, amount: float)  # Used via emit in collect_resources()

# Visual components (to be set in scene)
var sprite: Sprite2D
var collection_area: Node2D

func _init(hex_pos: Vector2 = Vector2.ZERO):
	hex_position = hex_pos

func _ready():
	# Get references to child nodes
	sprite = get_node_or_null("Sprite2D")
	collection_area = get_node_or_null("CollectionArea")

	# Building is complete by default when placed
	complete_construction()

func _process(delta):
	if construction_complete:
		collection_timer += delta
		if collection_timer >= collection_interval:
			collect_resources()
			collection_timer = 0.0

func setup(grid: HexGrid, manager: Node):
	hex_grid = grid
	building_manager = manager

func collect_resources():
	# Override in specific building types
	pass

func get_building_info() -> String:
	var info = "Building: %s\n" % building_name
	info += "Health: %.0f/%.0f\n" % [health, max_health]
	info += "Status: %s\n" % ("Complete" if construction_complete else "Under Construction")
	if not resource_production.is_empty():
		info += "Production:\n"
		for resource_type in resource_production.keys():
			info += "  %s: %.1f/min\n" % [resource_type, resource_production[resource_type] * 20]
	return info

func can_be_built_on_hex(hex_tile: HexTile) -> bool:
	return not hex_tile.is_occupied and hex_tile.has_resource

func start_construction():
	construction_complete = false

func complete_construction():
	construction_complete = true
	if sprite:
		sprite.modulate = Color.WHITE  # Full color when complete
