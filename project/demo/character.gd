extends Node3D

@export var mouse_sensitivity = 0.02

var mult = 5

@onready var axisx = $AxisX
@onready var _camera = $AxisX/DemoCamera

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		var raw_input = Input.get_vector("left", "right", "forward", "back")

		var input := Vector3.ZERO
		# This is to ensure that diagonal input isn't stronger than axis aligned input
		input.x = raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
		input.z = raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)
		
		input = _camera.global_transform.basis * input
		
		input.y = Input.get_axis("down", "up")
		
		position += input*delta*mult


func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	if event is InputEventMouseMotion:
		var move = event.relative
		
		rotate_y(-move.x*mouse_sensitivity)
		axisx.rotate_x(-move.y*mouse_sensitivity)
	
	if event is InputEventMouseButton:
		event as InputEventMouseButton
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mult -= 1
			mult = clamp(mult, 0, 150)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			mult += 1
			mult = clamp(mult, 0, 150)
