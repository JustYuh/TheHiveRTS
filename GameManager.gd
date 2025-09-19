extends Node

@onready var hex_renderer: HexRenderer = $"../GridSystem/HexRenderer"
@onready var camera_controller: CameraController = $"../CameraController"

var hex_grid: HexGrid

func _ready():
	print("Starting game...")
	setup_game()
	print("Game ready!")

func setup_game():
	hex_grid = HexGrid.new()
	hex_grid.hex_radius = 12
	hex_grid.hex_size = 35.0
	hex_grid.generate_grid()
	
	hex_renderer.setup(hex_grid)
	camera_controller.setup_with_grid(hex_grid)
	camera_controller.hex_clicked.connect(_on_hex_clicked)
	
	print("Created ", hex_grid.grid_data.size(), " hexes")

func _on_hex_clicked(hex_coord: Vector2):
	print("Game received hex click: ", hex_coord)
