class_name CameraController
extends Camera2D

@export var pan_speed: float = 800.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.3
@export var max_zoom: float = 3.0

var is_panning: bool = false
var last_mouse_pos: Vector2
var hex_grid: HexGrid

signal hex_clicked(hex_coord: Vector2, world_position: Vector2)

func _ready():
	make_current()

func setup_with_grid(grid: HexGrid):
	hex_grid = grid

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				start_pan(event.position)
			else:
				stop_pan()
		# Left click is now handled by InputManager, not here

	elif event is InputEventMouseMotion and is_panning:
		pan_camera(event.position)

func _process(delta):
	var movement = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): movement.y -= 1
	if Input.is_key_pressed(KEY_S): movement.y += 1
	if Input.is_key_pressed(KEY_A): movement.x -= 1
	if Input.is_key_pressed(KEY_D): movement.x += 1
	if Input.is_key_pressed(KEY_Q): zoom_out()
	if Input.is_key_pressed(KEY_E): zoom_in()
	if Input.is_key_pressed(KEY_HOME): reset_camera()
	
	if movement != Vector2.ZERO:
		global_position += movement * pan_speed * delta / zoom.x

func start_pan(mouse_pos: Vector2):
	is_panning = true
	last_mouse_pos = mouse_pos

func stop_pan():
	is_panning = false

func pan_camera(mouse_pos: Vector2):
	var delta = (last_mouse_pos - mouse_pos) / zoom.x
	global_position += delta
	last_mouse_pos = mouse_pos

func zoom_in():
	zoom = Vector2.ONE * clamp(zoom.x + zoom_speed, min_zoom, max_zoom)

func zoom_out():
	zoom = Vector2.ONE * clamp(zoom.x - zoom_speed, min_zoom, max_zoom)

func reset_camera():
	global_position = Vector2.ZERO
	zoom = Vector2.ONE

# detect_hex() function removed - now handled by InputManager
