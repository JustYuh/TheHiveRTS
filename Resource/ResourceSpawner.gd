# ResourceSpawner.gd - Simple version that will definitely work
class_name ResourceSpawner
extends RefCounted

# Configuration for resource spawning behavior
var seed_value: int

func _init(p_seed: int = 0):
	if p_seed == 0:
		seed_value = randi()
	else:
		seed_value = p_seed
	
	# Set seed for reproducible results during development
	seed(seed_value)

# Main function to populate hex grid with resources
func populate_grid(hex_grid: HexGrid) -> void:
	print("ResourceSpawner: Populating grid with seed: ", seed_value)
	
	# Simple approach: Just place resources based on rarity
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		var resource_type = _roll_for_resource_type()
		
		if resource_type != ResourceType.Type.NONE:
			_place_resource_on_hex(hex_tile, resource_type)
	
	print("ResourceSpawner: Grid population complete")

# Roll for resource type based on rarity probabilities
func _roll_for_resource_type() -> ResourceType.Type:
	var roll = randf()
	return ResourceType.get_type_by_rarity_roll(roll)

# Place a resource on a hex tile with randomized attributes
func _place_resource_on_hex(hex_tile: HexTile, resource_type: ResourceType.Type) -> void:
	var resource = ResourceType.new(resource_type)
	var instance_data = resource.generate_instance_data()
	
	hex_tile.resource_type = resource_type
	hex_tile.resource_data = instance_data
	hex_tile.has_resource = true

# Get statistics about resource distribution (for debugging and balancing)
func get_distribution_stats(hex_grid: HexGrid) -> Dictionary:
	var stats = {
		"total_hexes": hex_grid.grid_data.size(),
		"empty_hexes": 0,
		"resource_counts": {},
		"total_resources": 0
	}
	
	# Initialize resource counters
	for type in ResourceType.get_all_types():
		var resource = ResourceType.new(type)
		stats.resource_counts[resource.name] = 0
	
	# Count resources
	for hex_coord in hex_grid.grid_data.keys():
		var hex_tile = hex_grid.grid_data[hex_coord]
		if hex_tile.has_resource:
			var resource = ResourceType.new(hex_tile.resource_type)
			stats.resource_counts[resource.name] += 1
			stats.total_resources += 1
		else:
			stats.empty_hexes += 1
	
	return stats
