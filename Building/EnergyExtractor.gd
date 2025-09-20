# EnergyExtractor.gd
# Specialized building for extracting energy resources
class_name EnergyExtractor
extends Building

func _ready():
	super._ready()
	building_name = "Energy Extractor"
	resource_cost = {"steel": 50, "crystal": 10}
	resource_production = {"energy": 2.5}  # Per collection cycle

	# Set visual appearance (sprite is set by parent _ready())
	if sprite:
		sprite.modulate = Color.YELLOW

func collect_resources():
	if not hex_grid or not hex_grid.has_hex(hex_position):
		return

	var hex_tile = hex_grid.get_hex(hex_position)
	if not hex_tile or not hex_tile.has_resource:
		return

	# Check if this hex has energy-type resources (silica or crystal)
	var can_extract = (hex_tile.resource_type == ResourceType.Type.SILICA or
					  hex_tile.resource_type == ResourceType.Type.CRYSTAL)

	if can_extract:
		var amount = resource_production["energy"]

		# Bonus based on resource purity
		if hex_tile.resource_data.has("purity"):
			var purity_bonus = hex_tile.resource_data.purity / 100.0
			amount *= purity_bonus

		resource_collected.emit("energy", amount)
		print("Energy Extractor collected %.1f energy from %s" % [amount, hex_tile.get_resource().name])

func can_be_built_on_hex(hex_tile: HexTile) -> bool:
	if not super.can_be_built_on_hex(hex_tile):
		return false

	# Can only be built on energy-producing resources
	return (hex_tile.resource_type == ResourceType.Type.SILICA or
			hex_tile.resource_type == ResourceType.Type.CRYSTAL)