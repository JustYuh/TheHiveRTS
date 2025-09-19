# HoverInfoManager.gd
# Dedicated manager for hover information UI system
class_name HoverInfoManager
extends Node

# References to game systems
var hex_grid: HexGrid
var camera_controller: CameraController

# Hover info box system
var hover_info_box: Control
var hover_timer: Timer
var current_hover_hex: Vector2 = Vector2.INF
var hover_delay: float = 0.8  # Seconds before info appears
var info_box_offset: Vector2 = Vector2(10, -60)

# Settings
@export var enabled: bool = true
@export var hover_delay_time: float = 0.8
@export var info_box_size: Vector2 = Vector2(200, 120)

func _ready():
	_setup_hover_system()

func setup(p_hex_grid: HexGrid, p_camera: CameraController):
	"""Initialize the hover system with game components"""
	hex_grid = p_hex_grid
	camera_controller = p_camera
	print("HoverInfoManager: Setup complete")

func _setup_hover_system():
	"""Create the hover UI components"""
	# Create hover timer
	hover_timer = Timer.new()
	hover_timer.wait_time = hover_delay_time
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_show_hover_info)
	add_child(hover_timer)
	
	# Create info box container
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "HoverUILayer"
	add_child(canvas_layer)
	
	hover_info_box = Control.new()
	hover_info_box.name = "HoverInfoBox"
	hover_info_box.visible = false
	hover_info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
	canvas_layer.add_child(hover_info_box)
	
	# Info box background panel - will be resized dynamically
	var bg_panel = Panel.new()
	bg_panel.name = "BgPanel"
	_style_info_panel(bg_panel)
	hover_info_box.add_child(bg_panel)
	
	# Info text label - will calculate its own size
	var info_label = RichTextLabel.new()
	info_label.name = "InfoLabel"
	info_label.fit_content = true
	info_label.bbcode_enabled = true
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.position = Vector2(8, 8)  # Padding from panel edge
	info_label.add_theme_color_override("default_color", Color.WHITE)
	info_label.add_theme_font_size_override("normal_font_size", 12)
	bg_panel.add_child(info_label)

func _style_info_panel(panel: Panel):
	"""Apply styling to the info panel"""
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.95)  # Dark semi-transparent
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.7, 1.0, 0.8)  # Light blue border
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style_box)

func _input(event):
	"""Handle input events for hover detection"""
	if not enabled:
		return
	
	if event is InputEventMouseMotion:
		_handle_mouse_hover()

func _handle_mouse_hover():
	"""Process mouse hover over hexes"""
	if not hex_grid or not camera_controller:
		return
	
	# Get world position under mouse
	var world_pos = camera_controller.get_global_mouse_position()
	var hex_coord = hex_grid.world_to_axial(world_pos)
	
	# Check if we're hovering over a valid hex
	if hex_grid.has_hex(hex_coord):
		if hex_coord != current_hover_hex:
			# Started hovering over a new hex
			current_hover_hex = hex_coord
			hover_timer.start()
			_hide_hover_info()
	else:
		# Not hovering over any hex
		_stop_hover()

func _stop_hover():
	"""Stop the hover process"""
	current_hover_hex = Vector2.INF
	hover_timer.stop()
	_hide_hover_info()

func _show_hover_info():
	"""Display the hover information box"""
	if current_hover_hex == Vector2.INF or not hex_grid:
		return
	
	var hex_tile = hex_grid.grid_data[current_hover_hex]
	if not hex_tile:
		return
	
	# Update info text first
	var info_text = _generate_hover_text(hex_tile)
	var bg_panel = hover_info_box.get_node("BgPanel")
	if not bg_panel:
		return
	
	var info_label = bg_panel.get_node("InfoLabel")
	if not info_label:
		return
	
	info_label.text = info_text
	
	# Wait one frame for the label to calculate its content size
	await get_tree().process_frame
	
	# Get the actual content size from the label
	var content_size = info_label.get_content_height()
	var line_count = info_text.count("\n") + 1
	
	# Calculate adaptive size with padding
	var padding = Vector2(16, 16)  # 8px padding on each side
	var min_width = 180
	var adaptive_width = max(min_width, info_label.get_theme_font("normal_font").get_string_size(info_text.get_slice("\n", 0)).x + padding.x)
	var adaptive_height = max(content_size + padding.y, line_count * 16 + padding.y)
	
	# Resize the panel to fit content
	bg_panel.custom_minimum_size = Vector2(adaptive_width, adaptive_height)
	bg_panel.size = Vector2(adaptive_width, adaptive_height)
	
	# Update label size to match (minus padding)
	info_label.custom_minimum_size = Vector2(adaptive_width - padding.x, adaptive_height - padding.y)
	info_label.size = Vector2(adaptive_width - padding.x, adaptive_height - padding.y)
	
	# Position the info box near the mouse
	var mouse_pos = get_viewport().get_mouse_position()
	hover_info_box.position = mouse_pos + info_box_offset
	
	# Ensure info box stays on screen with new size
	_clamp_info_box_to_screen(Vector2(adaptive_width, adaptive_height))
	
	# Show the info box
	hover_info_box.visible = true

func _hide_hover_info():
	"""Hide the hover information box"""
	if hover_info_box:
		hover_info_box.visible = false

func _clamp_info_box_to_screen(box_size: Vector2 = info_box_size):
	"""Ensure the info box stays within screen bounds"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Keep within right edge
	if hover_info_box.position.x + box_size.x + 20 > viewport_size.x:
		hover_info_box.position.x = viewport_size.x - box_size.x - 20
	
	# Keep within left edge
	if hover_info_box.position.x < 10:
		hover_info_box.position.x = 10
	
	# Keep within top edge
	if hover_info_box.position.y < 10:
		hover_info_box.position.y = 10
	
	# Keep within bottom edge
	if hover_info_box.position.y + box_size.y + 10 > viewport_size.y:
		hover_info_box.position.y = viewport_size.y - box_size.y - 10

func _generate_hover_text(hex_tile: HexTile) -> String:
	"""Generate the rich text content for the hover box"""
	var text = ""
	
	# Hex coordinates
	text += "[color=cyan]Hex (%d, %d)[/color]\n" % [hex_tile.hex_coord.x, hex_tile.hex_coord.y]
	
	if hex_tile.has_resource:
		var resource = hex_tile.get_resource()
		var data = hex_tile.resource_data
		
		# Resource name with color coding
		var resource_color = _get_resource_color(resource.type)
		text += "[color=%s][b]%s[/b][/color]\n" % [resource_color, resource.name]
		text += "[color=yellow]%s[/color]\n\n" % _get_rarity_description(resource.rarity)
		
		# Resource stats with color coding
		if data.has("purity"):
			var purity_color = _get_purity_color(data.purity)
			text += "[color=%s]Purity: %.1f%%[/color]\n" % [purity_color, data.purity]
		
		if data.has("yield"):
			text += "Yield: [color=cyan]%.1f/hr[/color]\n" % data.yield
		
		if data.has("risk_factor"):
			var risk_color = _get_risk_color(data.risk_factor)
			text += "[color=%s]Risk: %.0f%%[/color]\n" % [risk_color, data.risk_factor * 100]
		
		# Strategic value
		var strategic_value = hex_tile.calculate_strategic_value()
		var value_color = _get_value_color(strategic_value)
		text += "[color=%s]Value: %.0f[/color]" % [value_color, strategic_value]
		
	else:
		text += "[color=gray][i]Empty Hex[/i][/color]\n"
		text += "No resources detected"
	
	return text

func _get_resource_color(resource_type: ResourceType.Type) -> String:
	"""Get the display color for a resource type"""
	match resource_type:
		ResourceType.Type.SILICA:
			return "burlywood"
		ResourceType.Type.CHEMICAL:
			return "lime"
		ResourceType.Type.STEEL:
			return "gray"
		ResourceType.Type.CRYSTAL:
			return "magenta"
		_:
			return "white"

func _get_purity_color(purity: float) -> String:
	"""Get color based on purity level"""
	if purity > 80:
		return "lime"
	elif purity > 60:
		return "yellow"
	else:
		return "orange"

func _get_risk_color(risk_factor: float) -> String:
	"""Get color based on risk level"""
	if risk_factor < 0.3:
		return "lime"
	elif risk_factor < 0.6:
		return "yellow"
	else:
		return "red"

func _get_value_color(value: float) -> String:
	"""Get color based on strategic value"""
	if value > 80:
		return "lime"
	elif value > 40:
		return "yellow"
	else:
		return "gray"

func _get_rarity_description(rarity: float) -> String:
	"""Get human-readable rarity description"""
	if rarity > 0.3:
		return "Common"
	elif rarity > 0.1:
		return "Uncommon"
	elif rarity > 0.05:
		return "Rare"
	else:
		return "Super Rare"

# Public control functions
func enable_hover():
	"""Enable the hover system"""
	enabled = true

func disable_hover():
	"""Disable the hover system"""
	enabled = false
	_stop_hover()

func set_hover_delay(delay: float):
	"""Change the hover delay time"""
	hover_delay_time = delay
	if hover_timer:
		hover_timer.wait_time = delay

func set_info_box_size(size: Vector2):
	"""Change the info box dimensions"""
	info_box_size = size
	if hover_info_box:
		var bg_panel = hover_info_box.get_node("BgPanel")
		if bg_panel:
			bg_panel.custom_minimum_size = size
