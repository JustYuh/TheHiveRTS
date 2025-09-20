# ColonyHub.gd
# Central hub building for colony management
class_name ColonyHub
extends Building

func _ready():
	super._ready()
	building_name = "Colony Hub"
	resource_cost = {"silica": 100, "steel": 50, "materials": 25}
	collection_interval = 5.0  # Slower collection

	# Set visual appearance (sprite is set by parent _ready())
	if sprite:
		sprite.modulate = Color.WHITE

func collect_resources():
	# Colony hubs provide passive bonuses and don't directly extract
	# They could provide storage, coordination bonuses, etc.
	resource_collected.emit("coordination", 1.0)
	print("Colony Hub providing coordination bonus")

func can_be_built_on_hex(hex_tile: HexTile) -> bool:
	# Colony hubs can be built on any unoccupied hex (even empty ones)
	return not hex_tile.is_occupied