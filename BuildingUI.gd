# BuildingUI.gd
# User interface for building placement and resource display
class_name BuildingUI
extends Control

# Building scenes
var energy_extractor_scene = preload("res://Building/EnergyExtractor.tscn")
var material_processor_scene = preload("res://Building/MaterialProcessor.tscn")
var colony_hub_scene = preload("res://Building/ColonyHub.tscn")

# UI references - Top Bar Dropdown
@onready var top_bar = $TopBar
@onready var build_menu_btn = $TopBar/HBoxContainer/BuildMenuBtn
@onready var dropdown_panel = $DropdownPanel

# Building buttons
@onready var energy_extractor_btn = $DropdownPanel/Content/BuildingRow/EnergyExtractorBtn
@onready var material_processor_btn = $DropdownPanel/Content/BuildingRow/MaterialProcessorBtn
@onready var colony_hub_btn = $DropdownPanel/Content/BuildingRow/ColonyHubBtn
@onready var cancel_btn = $DropdownPanel/Content/BuildingRow/CancelBtn

# Labels
@onready var mode_label = $TopBar/HBoxContainer/ModeLabel
@onready var status_label = $DropdownPanel/Content/StatusLabel
@onready var energy_label = $TopBar/HBoxContainer/ResourceContainer/EnergyLabel
@onready var materials_label = $TopBar/HBoxContainer/ResourceContainer/MaterialsLabel
@onready var silica_label = $TopBar/HBoxContainer/ResourceContainer/SilicaLabel
@onready var steel_label = $TopBar/HBoxContainer/ResourceContainer/SteelLabel

# State
var selected_building_type: String = ""
var building_manager: Node

# Dropdown state
var is_dropdown_open: bool = false
var dropdown_target_height: float = 120.0

# Signals
signal building_selected(building_type: String, building_scene: PackedScene)
signal building_cancelled

# Resource tracking
var resources: Dictionary = {
	"energy": 0.0,
	"materials": 0.0,
	"silica": 0.0,
	"steel": 0.0,
	"crystal": 0.0,
	"coordination": 0.0
}

func _ready():
	# Make sure node references are valid
	if not energy_extractor_btn:
		print("ERROR: BuildingUI could not find EnergyExtractorBtn")
		return

	# Connect building button signals
	energy_extractor_btn.pressed.connect(_on_energy_extractor_selected)
	material_processor_btn.pressed.connect(_on_material_processor_selected)
	colony_hub_btn.pressed.connect(_on_colony_hub_selected)
	cancel_btn.pressed.connect(_on_cancel_selection)

	# Connect dropdown toggle
	build_menu_btn.pressed.connect(_on_build_menu_toggle)

	# Set initial dropdown state
	dropdown_panel.visible = false
	is_dropdown_open = false

	# Initial update
	update_resource_display()
	update_status("Click a building type above")
	print("BuildingUI: Top bar dropdown initialized and ready")

func setup(manager: Node):
	building_manager = manager

# Dropdown controls
func _on_build_menu_toggle():
	is_dropdown_open = !is_dropdown_open

	if is_dropdown_open:
		_open_dropdown()
	else:
		_close_dropdown()

func _open_dropdown():
	dropdown_panel.visible = true
	var tween = create_tween()
	tween.tween_property(dropdown_panel, "custom_minimum_size:y", dropdown_target_height, 0.2)
	tween.tween_property(dropdown_panel, "size:y", dropdown_target_height, 0.2)
	build_menu_btn.text = "🏗 BUILD MENU ▲"

func _close_dropdown():
	var tween = create_tween()
	tween.tween_property(dropdown_panel, "custom_minimum_size:y", 0, 0.2)
	tween.tween_property(dropdown_panel, "size:y", 0, 0.2)
	tween.tween_callback(_hide_dropdown)
	build_menu_btn.text = "🏗 BUILD MENU ▼"

func _hide_dropdown():
	dropdown_panel.visible = false

func _on_energy_extractor_selected():
	selected_building_type = "EnergyExtractor"
	building_selected.emit("EnergyExtractor", energy_extractor_scene)
	update_status("Energy Extractor selected
Click SILICA or CRYSTAL hex")
	_update_button_states()

func _on_material_processor_selected():
	selected_building_type = "MaterialProcessor"
	building_selected.emit("MaterialProcessor", material_processor_scene)
	update_status("Material Processor selected
Click CHEMICAL or STEEL hex")
	_update_button_states()

func _on_colony_hub_selected():
	selected_building_type = "ColonyHub"
	building_selected.emit("ColonyHub", colony_hub_scene)
	update_status("Colony Hub selected
Click any empty hex")
	_update_button_states()

func _on_cancel_selection():
	selected_building_type = ""
	building_cancelled.emit()
	update_status("Click a building type above")
	_update_button_states()

func _update_button_states():
	# Visual feedback for selected building
	if energy_extractor_btn:
		energy_extractor_btn.button_pressed = (selected_building_type == "EnergyExtractor")
	if material_processor_btn:
		material_processor_btn.button_pressed = (selected_building_type == "MaterialProcessor")
	if colony_hub_btn:
		colony_hub_btn.button_pressed = (selected_building_type == "ColonyHub")

	# Color coding for affordability
	_update_button_affordability()

func update_status(message: String):
	if status_label:
		status_label.text = message

func update_mode_display(mode_text: String):
	if mode_label:
		mode_label.text = "MODE: " + mode_text

func add_resource(resource_type: String, amount: float):
	if resources.has(resource_type):
		resources[resource_type] += amount
		update_resource_display()
		print("Added %.1f %s (Total: %.1f)" % [amount, resource_type, resources[resource_type]])

func update_resource_display():
	if energy_label:
		energy_label.text = "⚡%.0f" % resources.energy
	if materials_label:
		materials_label.text = "⚙%.0f" % resources.materials
	if silica_label:
		silica_label.text = "🟫%.0f" % resources.silica
	if steel_label:
		steel_label.text = "⚒%.0f" % resources.steel

	# Update button colors based on affordability
	_update_button_affordability()

func can_afford_building(building_type: String) -> bool:
	var costs = _get_building_costs(building_type)
	for resource_type in costs.keys():
		if resources.get(resource_type, 0) < costs[resource_type]:
			return false
	return true

func spend_resources(building_type: String) -> bool:
	if not can_afford_building(building_type):
		return false

	var costs = _get_building_costs(building_type)
	for resource_type in costs.keys():
		resources[resource_type] -= costs[resource_type]

	update_resource_display()
	return true

func _get_building_costs(building_type: String) -> Dictionary:
	match building_type:
		"EnergyExtractor":
			return {"steel": 50, "crystal": 10}
		"MaterialProcessor":
			return {"silica": 75, "steel": 25}
		"ColonyHub":
			return {"silica": 100, "steel": 50, "materials": 25}
		_:
			return {}

func _update_button_affordability():
	# Show green for affordable, red for too expensive
	var green = Color.GREEN
	var red = Color.LIGHT_CORAL
	var white = Color.WHITE

	if energy_extractor_btn:
		if can_afford_building("EnergyExtractor"):
			energy_extractor_btn.modulate = green
		else:
			energy_extractor_btn.modulate = red

	if material_processor_btn:
		if can_afford_building("MaterialProcessor"):
			material_processor_btn.modulate = green
		else:
			material_processor_btn.modulate = red

	if colony_hub_btn:
		if can_afford_building("ColonyHub"):
			colony_hub_btn.modulate = green
		else:
			colony_hub_btn.modulate = red

	# Cancel button always white
	if cancel_btn:
		cancel_btn.modulate = white
