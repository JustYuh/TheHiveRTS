# InputManager.gd
# Centralized input handling with proper priority and interaction modes
class_name InputManager
extends Node

enum InteractionMode {
	INSPECT,    # Default - click hexes to inspect
	BUILD       # Building placement mode
}

# Core systems
var hex_grid: HexGrid
var camera_controller: CameraController
var building_manager: BuildingManager
var building_ui: BuildingUI

# Interaction state
var current_mode: InteractionMode = InteractionMode.INSPECT
var selected_building_type: String = ""
var selected_building_scene: PackedScene
var is_ui_hovered: bool = false

# Building preview
var building_preview: Node2D
var preview_hex_coord: Vector2 = Vector2.INF
var preview_valid: bool = false

# Signals
signal hex_clicked(hex_coord: Vector2, world_position: Vector2)
signal building_placement_requested(building_type: String, hex_coord: Vector2)

func _ready():
	print("InputManager: Initialized")

func setup(grid: HexGrid, camera: CameraController, build_mgr: BuildingManager, ui: BuildingUI):
	hex_grid = grid
	camera_controller = camera
	building_manager = build_mgr
	building_ui = ui

	# Connect to UI signals
	building_ui.building_selected.connect(_on_building_selected)
	building_ui.building_cancelled.connect(_on_building_cancelled)

	print("InputManager: Connected to all systems")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_left_click()

func _process(_delta):
	_update_building_preview()
	_check_ui_hover()

func _handle_left_click():
	# Priority 1: UI interactions (handled by UI itself)
	if is_ui_hovered:
		return  # Let UI handle it

	# Priority 2: Game world interactions
	var world_pos = camera_controller.get_global_mouse_position()
	var hex_coord = hex_grid.world_to_axial(world_pos)

	if not hex_grid.has_hex(hex_coord):
		return

	match current_mode:
		InteractionMode.INSPECT:
			_handle_hex_inspection(hex_coord, world_pos)
		InteractionMode.BUILD:
			_handle_building_placement(hex_coord, world_pos)

func _handle_hex_inspection(hex_coord: Vector2, world_pos: Vector2):
	# Emit signal for inspection (GameManager handles this)
	hex_clicked.emit(hex_coord, world_pos)
	print("InputManager: Inspecting hex at %s" % hex_coord)

func _handle_building_placement(hex_coord: Vector2, world_pos: Vector2):
	if selected_building_type == "":
		return

	var hex_tile = hex_grid.get_hex(hex_coord)
	if not hex_tile:
		return

	# Check if placement is valid
	if _is_placement_valid(hex_tile):
		building_placement_requested.emit(selected_building_type, hex_coord)
		print("InputManager: Requesting building placement: %s at %s" % [selected_building_type, hex_coord])
	else:
		print("InputManager: Invalid placement location")

func _is_placement_valid(hex_tile: HexTile) -> bool:
	if selected_building_type == "":
		return false

	# Create temporary building to check validity
	var temp_building = selected_building_scene.instantiate() as Building
	var valid = temp_building.can_be_built_on_hex(hex_tile)
	temp_building.queue_free()

	return valid and building_ui.can_afford_building(selected_building_type)

func _on_building_selected(building_type: String, building_scene: PackedScene):
	current_mode = InteractionMode.BUILD
	selected_building_type = building_type
	selected_building_scene = building_scene
	_create_building_preview()
	_update_ui_mode_display()
	print("InputManager: Switched to BUILD mode - %s" % building_type)

func _on_building_cancelled():
	current_mode = InteractionMode.INSPECT
	selected_building_type = ""
	selected_building_scene = null
	_destroy_building_preview()
	_update_ui_mode_display()
	print("InputManager: Switched to INSPECT mode")

func _update_ui_mode_display():
	if building_ui:
		building_ui.update_mode_display(get_mode_name())

func _create_building_preview():
	_destroy_building_preview()

	if not selected_building_scene:
		return

	building_preview = selected_building_scene.instantiate()
	building_preview.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent

	# Add to scene but don't make it functional
	get_tree().current_scene.add_child(building_preview)

func _destroy_building_preview():
	if building_preview:
		building_preview.queue_free()
		building_preview = null

func _update_building_preview():
	if not building_preview or current_mode != InteractionMode.BUILD:
		return

	var world_pos = camera_controller.get_global_mouse_position()
	var hex_coord = hex_grid.world_to_axial(world_pos)

	# Only update if hex changed
	if hex_coord == preview_hex_coord:
		return

	preview_hex_coord = hex_coord

	if hex_grid.has_hex(hex_coord):
		var hex_tile = hex_grid.get_hex(hex_coord)
		building_preview.global_position = hex_tile.world_position

		# Update preview validity color
		preview_valid = _is_placement_valid(hex_tile)
		if preview_valid:
			building_preview.modulate = Color(0, 1, 0, 0.7)  # Green = valid
		else:
			building_preview.modulate = Color(1, 0, 0, 0.7)  # Red = invalid

		building_preview.visible = true
	else:
		building_preview.visible = false

func _check_ui_hover():
	# Check if mouse is over any UI elements
	var mouse_pos = get_viewport().get_mouse_position()
	is_ui_hovered = false

	if building_ui and building_ui.visible:
		# Check top bar
		var top_bar_rect = building_ui.top_bar.get_global_rect()
		is_ui_hovered = top_bar_rect.has_point(mouse_pos)

		# Check dropdown if open
		if building_ui.is_dropdown_open and building_ui.dropdown_panel.visible:
			var dropdown_rect = building_ui.dropdown_panel.get_global_rect()
			is_ui_hovered = is_ui_hovered or dropdown_rect.has_point(mouse_pos)

func get_current_mode() -> InteractionMode:
	return current_mode

func get_mode_name() -> String:
	match current_mode:
		InteractionMode.INSPECT:
			return "INSPECT"
		InteractionMode.BUILD:
			return "BUILD: " + selected_building_type
		_:
			return "UNKNOWN"