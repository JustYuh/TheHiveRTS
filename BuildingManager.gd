# BuildingManager.gd
# Manages building placement, validation, and resource collection
class_name BuildingManager
extends Node

# Core systems
var hex_grid: HexGrid
var camera_controller: CameraController
var building_ui: BuildingUI
var input_manager: InputManager

# Building state
var placed_buildings: Array[Building] = []

# Signals
signal building_placed(building: Building)
signal resources_updated(resource_type: String, amount: float)

func _ready():
	print("BuildingManager: Initialized")

func setup(grid: HexGrid, camera: CameraController, ui: BuildingUI, input_mgr: InputManager):
	hex_grid = grid
	camera_controller = camera
	building_ui = ui
	input_manager = input_mgr

	# Connect input manager signals for building placement
	input_manager.building_placement_requested.connect(_on_building_placement_requested)

	print("BuildingManager: Connected to systems")

func _on_building_placement_requested(building_type: String, hex_coord: Vector2):
	var hex_tile = hex_grid.get_hex(hex_coord)
	if not hex_tile:
		building_ui.update_status("Invalid hex tile")
		return

	# Try to place the building
	if attempt_building_placement(building_type, hex_coord, hex_tile):
		building_ui.update_status("Building placed successfully!")
	else:
		building_ui.update_status("Cannot place building here")

func attempt_building_placement(building_type: String, hex_coord: Vector2, hex_tile: HexTile) -> bool:
	# Get the building scene from UI
	var building_scene: PackedScene
	match building_type:
		"EnergyExtractor":
			building_scene = building_ui.energy_extractor_scene
		"MaterialProcessor":
			building_scene = building_ui.material_processor_scene
		"ColonyHub":
			building_scene = building_ui.colony_hub_scene
		_:
			return false

	# Create a temporary building to check placement validity
	var temp_building = building_scene.instantiate() as Building

	if not temp_building.can_be_built_on_hex(hex_tile):
		temp_building.queue_free()
		return false

	# Check resource costs
	if not building_ui.can_afford_building(building_type):
		temp_building.queue_free()
		return false

	# Spend resources
	if not building_ui.spend_resources(building_type):
		temp_building.queue_free()
		return false

	# Place the building
	place_building(temp_building, hex_coord, hex_tile)
	return true

func place_building(building: Building, hex_coord: Vector2, hex_tile: HexTile):
	# Set building position
	building.hex_position = hex_coord
	building.global_position = hex_tile.world_position

	# Mark hex as occupied
	hex_tile.is_occupied = true

	# Add to scene in the GameWorld/Buildings container for proper layering
	var game_world = get_tree().current_scene.get_node("GameWorld")
	if game_world:
		var buildings_container = game_world.get_node("Buildings")
		if buildings_container:
			buildings_container.add_child(building)
		else:
			game_world.add_child(building)
	else:
		# Fallback: add as child of BuildingManager
		add_child(building)

	building.setup(hex_grid, self)

	# Connect resource collection signal
	building.resource_collected.connect(_on_building_resource_collected)

	# Track the building
	placed_buildings.append(building)

	print("BuildingManager: Placed %s at %s" % [building.building_name, hex_coord])
	building_placed.emit(building)

func _on_building_resource_collected(resource_type: String, amount: float):
	# Forward to UI for tracking
	building_ui.add_resource(resource_type, amount)
	resources_updated.emit(resource_type, amount)

func get_building_at_hex(hex_coord: Vector2) -> Building:
	for building in placed_buildings:
		if building.hex_position == hex_coord:
			return building
	return null

func get_all_buildings() -> Array[Building]:
	return placed_buildings

func remove_building(building: Building):
	if building in placed_buildings:
		# Mark hex as unoccupied
		if hex_grid.has_hex(building.hex_position):
			var hex_tile = hex_grid.get_hex(building.hex_position)
			hex_tile.is_occupied = false

		# Remove from tracking
		placed_buildings.erase(building)
		building.queue_free()

		print("BuildingManager: Removed %s" % building.building_name)

func get_building_count_by_type(building_type: String) -> int:
	var count = 0
	for building in placed_buildings:
		if building.building_name.contains(building_type):
			count += 1
	return count

# Debug function to list all buildings
func list_all_buildings():
	print("=== BUILDING INVENTORY ===")
	print("Total buildings: %d" % placed_buildings.size())

	var building_counts = {}
	for building in placed_buildings:
		var type = building.building_name
		building_counts[type] = building_counts.get(type, 0) + 1

	for building_type in building_counts.keys():
		print("  %s: %d" % [building_type, building_counts[building_type]])

	print("==========================")