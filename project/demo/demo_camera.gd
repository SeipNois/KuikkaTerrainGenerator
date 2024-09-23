extends Camera3D

@export var hotkey: int = 1

func _input(event):
	if InputMap.has_action("camera_hotkey_%d" % hotkey) and \
	event.is_action_pressed("camera_hotkey_%d" % hotkey):
		current = true
