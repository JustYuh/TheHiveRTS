# ResourceType.gd
# Defines the different types of resources that can spawn on hex tiles
class_name ResourceType
extends Resource

enum Type {
	NONE,
	SILICA,      # Common - basic building material
	CHEMICAL,    # Uncommon - liquid processing resource  
	STEEL,       # Rare - advanced construction material
	CRYSTAL      # Super Rare - high-tech component
}

# Resource properties for analytical gameplay
var type: Type
var name: String
var rarity: float           # 0.0 = never spawns, 1.0 = always spawns
var base_yield: float       # Base extraction rate
var purity_range: Vector2   # Min/max purity percentages
var stability: float       # How stable the resource is (affects risk)
var color: Color           # Visual representation

func _init(p_type: Type = Type.NONE):
	type = p_type
	_setup_properties()

func _setup_properties():
	match type:
		Type.SILICA:
			name = "Silica"
			rarity = 0.15          # 35% spawn chance - common
			base_yield = 8.0
			purity_range = Vector2(60, 85)
			stability = 0.9        # Very stable
			color = Color(0.8, 0.7, 0.5, 0.8)  # Sandy brown
			
		Type.CHEMICAL:
			name = "Chemical Soup"
			rarity = 0.06          # 15% spawn chance - uncommon
			base_yield = 12.0
			purity_range = Vector2(40, 90)
			stability = 0.6        # Moderately volatile
			color = Color(0.2, 0.8, 0.3, 0.8)  # Toxic green
			
		Type.STEEL:
			name = "Steel Ore"
			rarity = 0.03          # 6% spawn chance - rare
			base_yield = 18.0
			purity_range = Vector2(70, 95)
			stability = 0.8        # Quite stable
			color = Color(0.3, 0.3, 0.4, 0.8)  # Darker metallic gray
			
		Type.CRYSTAL:
			name = "Quantum Crystal"
			rarity = 0.01          # 2% spawn chance - super rare
			base_yield = 35.0
			purity_range = Vector2(85, 99)
			stability = 0.3        # Highly volatile
			color = Color(0.8, 0.2, 0.9, 0.9)  # Purple crystal
			
		Type.NONE:
			name = "Empty"
			rarity = 0.0
			base_yield = 0.0
			purity_range = Vector2(0, 0)
			stability = 1.0
			color = Color.TRANSPARENT

# Generate randomized attributes for analytical gameplay
func generate_instance_data() -> Dictionary:
	if type == Type.NONE:
		return {}
	
	var instance_data = {}
	
	# Randomize purity within range
	instance_data.purity = randf_range(purity_range.x, purity_range.y)
	
	# Calculate yield based on purity (creates correlation for analysis)
	var purity_modifier = instance_data.purity / 100.0
	instance_data.yield = base_yield * purity_modifier
	
	# Add some randomness to yield (represents extraction difficulty)
	var yield_variance = randf_range(0.8, 1.2)
	instance_data.yield *= yield_variance
	
	# Risk factor based on stability and purity (high purity = higher risk)
	var base_risk = 1.0 - stability
	var purity_risk_bonus = (instance_data.purity - 50) / 100.0  # Higher purity = more risk
	instance_data.risk_factor = base_risk + purity_risk_bonus * 0.3
	instance_data.risk_factor = clamp(instance_data.risk_factor, 0.0, 1.0)
	
	# Market volatility (super rare = more volatile)
	instance_data.volatility = (1.0 - rarity) * 0.5 + randf() * 0.3
	
	return instance_data

# Static helper to get all resource types
static func get_all_types() -> Array[Type]:
	return [Type.SILICA, Type.CHEMICAL, Type.STEEL, Type.CRYSTAL]

# Helper to get resource type by rarity roll
static func get_type_by_rarity_roll(roll: float) -> Type:
	# Create cumulative probability distribution
	var types = get_all_types()
	var cumulative_chance = 0.0
	
	for resource_type in types:
		var resource = ResourceType.new(resource_type)
		cumulative_chance += resource.rarity
		if roll <= cumulative_chance:
			return resource_type
	
	return Type.NONE  # Empty hex
