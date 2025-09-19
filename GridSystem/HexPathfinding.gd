# HexPathfinding.gd
class_name HexPathfinding
extends RefCounted

# A* pathfinding implementation for hex grids
# This teaches players about optimal path analysis and cost-benefit thinking

class PathNode:
	var coordinate: Vector2
	var g_cost: float = 0.0      # Cost from start
	var h_cost: float = 0.0      # Heuristic cost to goal
	var f_cost: float = 0.0      # Total cost (g + h)
	var parent: PathNode = null
	var hex_tile: HexTile
	
	func _init(coord: Vector2, tile: HexTile):
		coordinate = coord
		hex_tile = tile
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# Find path between two hexes using A* algorithm
static func find_path(hex_grid: HexGrid, start: Vector2, goal: Vector2, 
					 consider_resources: bool = true) -> Array[Vector2]:
	
	if not (hex_grid.hex_tiles.has(start) and hex_grid.hex_tiles.has(goal)):
		print("Invalid start or goal position")
		return []
	
	var open_set: Array[PathNode] = []
	var closed_set: Dictionary = {}
	var all_nodes: Dictionary = {}
	
	# Create start node
	var start_node = PathNode.new(start, hex_grid.hex_tiles[start])
	start_node.g_cost = 0
	start_node.h_cost = hex_grid.heuristic_cost(start, goal)
	start_node.calculate_f_cost()
	
	open_set.append(start_node)
	all_nodes[start] = start_node
	
	while open_set.size() > 0:
		# Find node with lowest f_cost
		var current_node = open_set[0]
		var current_index = 0
		
		for i in range(1, open_set.size()):
			if open_set[i].f_cost < current_node.f_cost:
				current_node = open_set[i]
				current_index = i
		
		# Move current node from open to closed set
		open_set.remove_at(current_index)
		closed_set[current_node.coordinate] = current_node
		
		# Check if we reached the goal
		if current_node.coordinate == goal:
			return reconstruct_path(current_node)
		
		# Check all neighbors
		var neighbors = hex_grid.get_neighbors(current_node.coordinate)
		for neighbor_coord in neighbors:
			if closed_set.has(neighbor_coord):
				continue
			
			var neighbor_tile = hex_grid.hex_tiles[neighbor_coord]
			var tentative_g_cost = current_node.g_cost + calculate_movement_cost(
				current_node.hex_tile, neighbor_tile, consider_resources
			)
			
			# Create neighbor node if it doesn't exist
			var neighbor_node: PathNode
			if all_nodes.has(neighbor_coord):
				neighbor_node = all_nodes[neighbor_coord]
			else:
				neighbor_node = PathNode.new(neighbor_coord, neighbor_tile)
				neighbor_node.h_cost = hex_grid.heuristic_cost(neighbor_coord, goal)
				all_nodes[neighbor_coord] = neighbor_node
			
			# Update node if we found a better path
			if tentative_g_cost < neighbor_node.g_cost or not open_set.has(neighbor_node):
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.calculate_f_cost()
				neighbor_node.parent = current_node
				
				if not open_set.has(neighbor_node):
					open_set.append(neighbor_node)
	
	# No path found
	print("No path found from ", start, " to ", goal)
	return []

# Calculate movement cost between adjacent hexes with analytical considerations
static func calculate_movement_cost(_from_tile: HexTile, to_tile: HexTile, 
								   consider_resources: bool) -> float:
	var base_cost = 1.0
	
	if not consider_resources:
		return base_cost
	
	# Terrain difficulty affects movement
	var terrain_cost = to_tile.terrain_difficulty * 2.0
	
	# Processing complexity affects traversal (supply lines, equipment needs)
	var complexity_cost = to_tile.processing_complexity * 0.5
	
	# Energy instability makes movement risky/costly
	var stability_cost = (1.0 - to_tile.energy_stability) * 0.3
	
	# Risk assessment affects operational costs
	var risk_cost = to_tile.risk_assessment * 0.4
	
	# Total analytical cost - teaches players to consider multiple factors
	return base_cost + terrain_cost + complexity_cost + stability_cost + risk_cost

# Reconstruct the path from goal back to start
static func reconstruct_path(goal_node: PathNode) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var current_node = goal_node
	
	while current_node != null:
		path.push_front(current_node.coordinate)
		current_node = current_node.parent
	
	return path

# Find multiple paths with different optimization criteria
static func find_optimized_paths(hex_grid: HexGrid, start: Vector2, goal: Vector2) -> Dictionary:
	var paths = {}
	
	# Shortest path (ignore resources)
	paths["shortest"] = find_path(hex_grid, start, goal, false)
	
	# Resource-aware path (consider terrain and complexity)
	paths["efficient"] = find_path(hex_grid, start, goal, true)
	
	# Low-risk path (avoid high-risk hexes)
	paths["safe"] = find_safe_path(hex_grid, start, goal)
	
	return paths

# Find path that avoids high-risk areas
static func find_safe_path(hex_grid: HexGrid, start: Vector2, goal: Vector2) -> Array[Vector2]:
	# Temporarily increase costs for high-risk hexes
	var original_risks = {}
	
	for hex_coord in hex_grid.hex_tiles.keys():
		var tile = hex_grid.hex_tiles[hex_coord]
		original_risks[hex_coord] = tile.risk_assessment
		
		# Boost risk for pathfinding calculation
		if tile.risk_assessment > 0.6:
			tile.risk_assessment = tile.risk_assessment * 2.0
	
	# Find path with modified risk values
	var safe_path = find_path(hex_grid, start, goal, true)
	
	# Restore original risk values
	for hex_coord in original_risks.keys():
		hex_grid.hex_tiles[hex_coord].risk_assessment = original_risks[hex_coord]
	
	return safe_path

# Calculate total path cost for analysis
static func calculate_path_cost(hex_grid: HexGrid, path: Array[Vector2], 
							   consider_resources: bool = true) -> Dictionary:
	if path.size() < 2:
		return {"total_cost": 0.0, "distance": 0, "resource_cost": 0.0}
	
	var total_cost = 0.0
	var resource_cost = 0.0
	var distance = path.size() - 1
	
	for i in range(path.size() - 1):
		var from_coord = path[i]
		var to_coord = path[i + 1]
		
		if hex_grid.hex_tiles.has(from_coord) and hex_grid.hex_tiles.has(to_coord):
			var from_tile = hex_grid.hex_tiles[from_coord]
			var to_tile = hex_grid.hex_tiles[to_coord]
			
			var step_cost = calculate_movement_cost(from_tile, to_tile, consider_resources)
			total_cost += step_cost
			
			if consider_resources:
				resource_cost += step_cost - 1.0  # Subtract base cost to get resource penalty
	
	return {
		"total_cost": total_cost,
		"distance": distance,
		"resource_cost": resource_cost,
		"efficiency_ratio": distance / total_cost if total_cost > 0 else 0.0
	}

# Analyze and compare multiple paths - teaches optimization thinking
static func analyze_path_options(hex_grid: HexGrid, start: Vector2, goal: Vector2) -> Dictionary:
	var paths = find_optimized_paths(hex_grid, start, goal)
	var analysis = {}
	
	for path_type in paths.keys():
		var path = paths[path_type]
		if path.size() > 0:
			var cost_analysis = calculate_path_cost(hex_grid, path, true)
			analysis[path_type] = {
				"path": path,
				"cost_analysis": cost_analysis,
				"hexes_traversed": path.size(),
				"recommendation": get_path_recommendation(path_type, cost_analysis)
			}
	
	return analysis

# Provide analytical recommendations for path selection
static func get_path_recommendation(path_type: String, cost_analysis: Dictionary) -> String:
	match path_type:
		"shortest":
			if cost_analysis.efficiency_ratio > 0.8:
				return "Excellent efficiency - minimal detours"
			else:
				return "Direct but may have hidden costs"
		
		"efficient":
			if cost_analysis.resource_cost < 2.0:
				return "Well-optimized route with good resource management"
			else:
				return "Resource-heavy route - consider alternatives"
		
		"safe":
			if cost_analysis.total_cost < cost_analysis.distance * 1.5:
				return "Good balance of safety and efficiency"
			else:
				return "Very safe but expensive - use for critical missions"
		
		_:
			return "Path analysis complete"

# Find all hexes within movement range (for tactical analysis)
static func find_reachable_hexes(hex_grid: HexGrid, start: Vector2, 
								max_movement_cost: float) -> Dictionary:
	var reachable = {}
	var open_set: Array[PathNode] = []
	var closed_set: Dictionary = {}
	
	# Start node
	var start_node = PathNode.new(start, hex_grid.hex_tiles[start])
	start_node.g_cost = 0
	open_set.append(start_node)
	
	while open_set.size() > 0:
		var current_node = open_set.pop_front()
		closed_set[current_node.coordinate] = current_node
		reachable[current_node.coordinate] = current_node.g_cost
		
		# Check neighbors
		var neighbors = hex_grid.get_neighbors(current_node.coordinate)
		for neighbor_coord in neighbors:
			if closed_set.has(neighbor_coord):
				continue
			
			var neighbor_tile = hex_grid.hex_tiles[neighbor_coord]
			var movement_cost = calculate_movement_cost(current_node.hex_tile, neighbor_tile, true)
			var total_cost = current_node.g_cost + movement_cost
			
			if total_cost <= max_movement_cost:
				var neighbor_node = PathNode.new(neighbor_coord, neighbor_tile)
				neighbor_node.g_cost = total_cost
				neighbor_node.parent = current_node
				open_set.append(neighbor_node)
	
	return reachable
