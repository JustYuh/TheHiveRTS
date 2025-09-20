# MaterialProcessor.gd
# Specialized building for processing material resources
class_name MaterialProcessor
extends Building

func _ready():
	super._ready()
	building_name = "Material Processor"
	resource_cost = {"silica": 75, "steel": 25}
	resource_production = {"materials": 3.0}  # Per collection cycle

	# Set visual appearance (sprite is set by parent _ready())
	if sprite:
		sprite.modulate = Color.CYAN

func collect_resources():
	if not hex_grid or not hex_grid.has_hex(hex_position):
		return

	var hex_tile = hex_grid.get_hex(hex_position)
	if not hex_tile or not hex_tile.has_resource:
		return

	# Check if this hex has material-type resources (chemical or steel)
	var can_extract = (hex_tile.resource_type == ResourceType.Type.CHEMICAL or
					  hex_tile.resource_type == ResourceType.Type.STEEL)

	if can_extract:
		var amount = resource_production["materials"]

		# Bonus based on resource purity
		if hex_tile.resource_data.has("purity"):
			var purity_bonus = hex_tile.resource_data.purity / 100.0
			amount *= purity_bonus

		resource_collected.emit("materials", amount)
		print("Material Processor collected %.1f materials from %s" % [amount, hex_tile.get_resource().name])

func can_be_built_on_hex(hex_tile: HexTile) -> bool:
	if not super.can_be_built_on_hex(hex_tile):
		return false

	# Can only be built on material-producing resources
	return (hex_tile.resource_type == ResourceType.Type.CHEMICAL or
			hex_tile.resource_type == ResourceType.Type.STEEL)