# HexTile.gd
# Data container for individual hex tiles with resource support
class_name HexTile
extends RefCounted

# Position data
var hex_coord: Vector2      # Axial coordinates (q, r)
var world_position: Vector2 # World position for rendering

# Resource data - NEW for v0.2
var has_resource: bool = false
var resource_type: ResourceType.Type = ResourceType.Type.NONE
var resource_data: Dictionary = {}  # Stores purity, yield, risk, etc.

# Future expansion ready
var is_occupied: bool = false  # For units in future phases
var building_type = null       # For structures in future phases

func _init(p_hex_coord: Vector2, p_world_position: Vector2):
	hex_coord = p_hex_coord
	world_position = p_world_position

# Get the resource object for this hex (if any)
func get_resource() -> ResourceType:
	if has_resource:
		return ResourceType.new(resource_type)
	return null

# Get display information for UI/debugging
func get_resource_info() -> String:
	if not has_resource:
		return "Empty"
	
	var resource = get_resource()
	var info = resource.name
	
	if resource_data.has("purity"):
		info += " (%.1f%% purity)" % resource_data.purity
	
	return info

# Get the visual color for this hex
func get_display_color() -> Color:
	if has_resource:
		var resource = get_resource()
		# Modify alpha based on purity for visual feedback
		var color = resource.color
		if resource_data.has("purity"):
			var purity_factor = resource_data.purity / 100.0
			color.a = 0.5 + (purity_factor * 0.4)  # Range from 0.5 to 0.9 alpha
		return color
	
	# Default empty hex color - light baby blue
	return Color(0.7, 0.85, 1.0, 0.25)  # Light baby blue, very transparent

# Get analytical data for this hex (for future data visualization)
func get_analytical_data() -> Dictionary:
	var data = {
		"position": hex_coord,
		"has_resource": has_resource,
		"resource_type": resource_type
	}
	
	if has_resource:
		data.merge(resource_data)
	
	return data

# Calculate the strategic value of this hex for analytical gameplay
func calculate_strategic_value() -> float:
	if not has_resource:
		return 0.0
	
	var value = 0.0
	var resource = get_resource()
	
	# Base value from yield
	if resource_data.has("yield"):
		value += resource_data.yield
	
	# Adjust for risk (high risk reduces value)
	if resource_data.has("risk_factor"):
		value *= (1.0 - resource_data.risk_factor * 0.5)
	
	# Bonus for rare resources
	value *= (1.0 / resource.rarity) * 0.1
	
	return value
