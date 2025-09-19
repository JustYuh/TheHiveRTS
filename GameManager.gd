# GameManager.gd
# Main game coordinator with clean modular architecture
class_name GameManager
extends Node

# Core systems
var hex_grid: HexGrid
var hex_renderer: HexRenderer
var camera_controller: CameraController
var resource_spawner: ResourceSpawner
var hover_info_manager: HoverInfoManager  # NEW: Dedicated UI manager

# Configuration
@export var grid_radius: int = 12
@export var hex_size: float = 35.0
@export var resource_seed: int = 0  # 0 = random, any other number for reproducible maps

# Resource system
var resource_statistics: Dictionary = {}

# UI and debugging
@export var show_resource_stats: bool = true
@export var show_debug_info: bool = false

func _ready():
	print("GameManager: Initializing v0.2 'Resources' with clean architecture...")
	_setup_core_systems()
	_setup_resource_system()
	_setup_ui_systems()  # NEW: Separate UI setup
	_setup_connections()
	print("GameManager: v0.2 initialization complete!")

func _setup_core_systems():
	# Initialize hex grid
	hex_grid = HexGrid.new()
	hex_grid.hex_radius = grid_radius
	hex_grid.hex_size = hex_size
	hex_grid.generate_grid()
	print("GameManager: Hex grid created with ", hex_grid.grid_data.size(), " hexes")
	
	# Setup renderer (pure rendering only)
	hex_renderer = get_node("../GridSystem/HexRenderer")
	if hex_renderer == null:
		print("ERROR: Could not find HexRenderer node")
		return
	hex_renderer.hex_size = hex_size
	hex_renderer.setup(hex_grid)
	
	# Setup camera
	camera_controller = get_node("../CameraController")
	if camera_controller == null:
		print("ERROR: Could not find CameraController node")
		return
	camera_controller.setup_with_grid(hex_grid)

func _setup_resource_system():
	print("GameManager: Setting up resource spawning system...")
	
	# Create resource spawner
	resource_spawner = ResourceSpawner.new(resource_seed)
	
	# Populate the grid with resources
	resource_spawner.populate_grid(hex_grid)
	
	# Get statistics for analysis
	resource_statistics = resource_spawner.get_distribution_stats(hex_grid)
	
	# Print resource distribution stats
	_print_resource_stats()

func _setup_ui_systems():
	# Create and setup the hover info manager
	hover_info_manager = HoverInfoManager.new()
	hover_info_manager.name = "HoverInfoManager"
	add_child(hover_info_manager)
	hover_info_manager.setup(hex_grid, camera_controller)
	print("GameManager: UI systems initialized")

func _setup_connections():
	# Connect input handling for resource inspection
	camera_controller.hex_clicked.connect(_on_hex_clicked)

func _print_resource_stats():
	print("=== RESOURCE DISTRIBUTION STATISTICS ===")
	print("Total hexes: ", resource_statistics.total_hexes)
	print("Empty hexes: ", resource_statistics.empty_hexes)
	print("Total resources: ", resource_statistics.total_resources)
	print("Resource breakdown:")
	
	for resource_name in resource_statistics.resource_counts.keys():
		var count = resource_statistics.resource_counts[resource_name]
		var percentage = (float(count) / resource_statistics.total_hexes) * 100.0
		print("  - %s: %d hexes (%.1f%%)" % [resource_name, count, percentage])
	
	var resource_density = (float(resource_statistics.total_resources) / resource_statistics.total_hexes) * 100.0
	print("Overall resource density: %.1f%%" % resource_density)
	print("========================================")

func _on_hex_clicked(hex_coord: Vector2, _world_position: Vector2):
	print("\n=== HEX INSPECTION ===")
	print("Coordinates: (", hex_coord.x, ", ", hex_coord.y, ")")
	
	if hex_grid.grid_data.has(hex_coord):
		var hex_tile = hex_grid.grid_data[hex_coord]
		
		if hex_tile.has_resource:
			_print_detailed_resource_info(hex_tile)
		else:
			print("Status: Empty hex")
			print("Strategic value: 0.0")
	
	print("=====================\n")

func _print_detailed_resource_info(hex_tile: HexTile):
	var resource = hex_tile.get_resource()
	print("Resource: ", resource.name)
	print("Type: ", ResourceType.Type.keys()[hex_tile.resource_type])
	print("Rarity class: ", _get_rarity_description(resource.rarity))
	
	# Print analytical data
	if hex_tile.resource_data.has("purity"):
		print("Purity: %.1f%%" % hex_tile.resource_data.purity)
	
	if hex_tile.resource_data.has("yield"):
		print("Yield: %.1f units/hour" % hex_tile.resource_data.yield)
	
	if hex_tile.resource_data.has("risk_factor"):
		print("Risk factor: %.2f (%.1f%% risk)" % [hex_tile.resource_data.risk_factor, hex_tile.resource_data.risk_factor * 100])
	
	if hex_tile.resource_data.has("volatility"):
		print("Market volatility: %.2f" % hex_tile.resource_data.volatility)
	
	var strategic_value = hex_tile.calculate_strategic_value()
	print("Strategic value: %.1f" % strategic_value)
	
	# Analytical insights
	_print_analytical_insights(hex_tile)

func _print_analytical_insights(hex_tile: HexTile):
	var insights = []
	var resource = hex_tile.get_resource()
	var data = hex_tile.resource_data
	
	# Purity analysis
	if data.has("purity"):
		if data.purity > 85:
			insights.append("Exceptionally pure sample - high extraction efficiency")
		elif data.purity < 50:
			insights.append("Low purity - may require additional processing")
	
	# Risk-reward analysis
	if data.has("risk_factor") and data.has("yield"):
		var risk_reward_ratio = data.yield / (data.risk_factor + 0.1)
		if risk_reward_ratio > 50:
			insights.append("Excellent risk-reward ratio - priority target")
		elif risk_reward_ratio < 20:
			insights.append("Poor risk-reward ratio - consider alternatives")
	
	# Rarity value analysis
	if resource.rarity < 0.05:
		insights.append("Extremely rare resource - high strategic importance")
	elif resource.rarity > 0.3:
		insights.append("Common resource - reliable but low value")
	
	# Market volatility insights
	if data.has("volatility"):
		if data.volatility > 0.7:
			insights.append("High market volatility - timing will be crucial")
		elif data.volatility < 0.3:
			insights.append("Stable market conditions - predictable returns")
	
	if insights.size() > 0:
		print("Analytical insights:")
		for insight in insights:
			print("  • ", insight)

func _get_rarity_description(rarity: float) -> String:
	if rarity > 0.3:
		return "Common"
	elif rarity > 0.1:
		return "Uncommon"
	elif rarity > 0.05:
		return "Rare"
	else:
		return "Super Rare"

# Development and debugging functions
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_regenerate_resources()
			KEY_T:
				_toggle_display_mode()
			KEY_S:
				_print_resource_stats()
			KEY_A:
				_analyze_resource_patterns()

func _regenerate_resources():
	print("GameManager: Regenerating resources with new seed...")
	
	# Clear existing resources
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		hex_tile.has_resource = false
		hex_tile.resource_type = ResourceType.Type.NONE
		hex_tile.resource_data = {}
	
	# Generate new resources
	resource_spawner = ResourceSpawner.new()  # New random seed
	resource_spawner.populate_grid(hex_grid)
	resource_statistics = resource_spawner.get_distribution_stats(hex_grid)
	
	# Update display
	hex_renderer.queue_redraw()
	_print_resource_stats()

func _toggle_display_mode():
	hex_renderer.show_coordinates = !hex_renderer.show_coordinates
	hex_renderer.queue_redraw()
	
	var mode = "coordinates" if hex_renderer.show_coordinates else "clean"
	print("GameManager: Display mode toggled to ", mode)

func _analyze_resource_patterns():
	print("\n=== SPATIAL ANALYSIS ===")
	
	# Find resource clusters
	var clusters = _find_resource_clusters()
	print("Detected ", clusters.size(), " resource clusters:")
	
	for i in range(clusters.size()):
		var cluster = clusters[i]
		print("Cluster %d: %d hexes, primary resource: %s" % [i+1, cluster.hexes.size(), cluster.primary_resource])
	
	# Calculate resource distribution metrics
	var distribution_metrics = _calculate_distribution_metrics()
	print("\nDistribution Metrics:")
	print("  Clustering index: %.2f" % distribution_metrics.clustering_index)
	print("  Spatial diversity: %.2f" % distribution_metrics.spatial_diversity)
	print("  Edge resource ratio: %.2f" % distribution_metrics.edge_ratio)
	
	print("======================\n")

func _find_resource_clusters() -> Array:
	var clusters = []
	var processed_hexes = {}
	
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		
		if hex_tile.has_resource and not processed_hexes.has(hex_coord):
			var cluster = _explore_cluster(hex_coord, hex_tile.resource_type, processed_hexes)
			if cluster.hexes.size() >= 3:  # Only count clusters of 3+ hexes
				clusters.append(cluster)
	
	return clusters

func _explore_cluster(start_coord: Vector2, resource_type: ResourceType.Type, processed: Dictionary) -> Dictionary:
	var cluster = {
		"hexes": [],
		"primary_resource": ResourceType.new(resource_type).name
	}
	
	var to_explore = [start_coord]
	
	while to_explore.size() > 0:
		var current_coord = to_explore.pop_back()
		
		if processed.has(current_coord):
			continue
		
		var hex_tile = hex_grid.grid_data[current_coord]
		if hex_tile.has_resource and hex_tile.resource_type == resource_type:
			cluster.hexes.append(current_coord)
			processed[current_coord] = true
			
			# Add neighbors to explore
			var neighbors = hex_grid.get_neighbors(current_coord)
			for neighbor in neighbors:
				if not processed.has(neighbor):
					to_explore.append(neighbor)
	
	return cluster

func _calculate_distribution_metrics() -> Dictionary:
	var metrics = {}
	
	# Calculate clustering index (higher = more clustered)
	var total_neighbor_pairs = 0
	var same_resource_pairs = 0
	
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		if hex_tile.has_resource:
			var neighbors = []
			if hex_grid.has_method("get_neighbors"):
				neighbors = hex_grid.get_neighbors(hex_coord)
			else:
				neighbors = _get_neighbors_fallback(hex_coord)
			for neighbor_coord in neighbors:
				var neighbor_tile = hex_grid.grid_data[neighbor_coord]
				total_neighbor_pairs += 1
				if neighbor_tile.has_resource and neighbor_tile.resource_type == hex_tile.resource_type:
					same_resource_pairs += 1
	
	metrics.clustering_index = float(same_resource_pairs) / max(total_neighbor_pairs, 1)
	
	# Calculate spatial diversity (different resource types in local areas)
	var diversity_sum = 0.0
	var sample_count = 0
	
	for hex_coord in hex_grid.grid_data.keys():
		var neighbors = []
		if hex_grid.has_method("get_neighbors"):
			neighbors = hex_grid.get_neighbors(hex_coord)
		else:
			neighbors = _get_neighbors_fallback(hex_coord)
		var resource_types_nearby = {}
		
		for neighbor_coord in neighbors:
			var neighbor_tile = hex_grid.grid_data[neighbor_coord]
			if neighbor_tile.has_resource:
				resource_types_nearby[neighbor_tile.resource_type] = true
		
		if resource_types_nearby.size() > 0:
			diversity_sum += resource_types_nearby.size()
			sample_count += 1
	
	metrics.spatial_diversity = diversity_sum / max(sample_count, 1)
	
	# Calculate edge resource ratio
	var edge_resources = 0
	var total_resources = 0
	
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		if hex_tile.has_resource:
			total_resources += 1
			var distance_from_center = hex_grid.hex_distance(hex_coord, Vector2.ZERO)
			if distance_from_center > grid_radius * 0.7:
				edge_resources += 1
	
	metrics.edge_ratio = float(edge_resources) / max(total_resources, 1)
	
	return metrics

# Fallback function to get neighbors
func _get_neighbors_fallback(hex_coord: Vector2) -> Array:
	var neighbors = []
	var directions = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	
	for direction in directions:
		var neighbor_coord = hex_coord + direction
		if hex_grid.grid_data.has(neighbor_coord):
			neighbors.append(neighbor_coord)
	
	return neighbors
