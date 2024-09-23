@tool
class_name ZoomableMapContainer extends CenterContainer

## Container with ability to zoom and move single child relative to
## itself acting as container for e.g. map or image views.

@export var texture_rect : TextureRect
@export var tooltip : Label

var _mouse_in_area : bool = false
var _mouse_down : bool = false

var controlled_child : Control
var _pos_last_frame : Vector2

## Height range of image values.
var height_range : Vector2 = Vector2(0, 255)


# Called when the node enters the scene tree for the first time.
func _ready():
	mouse_entered.connect(_on_mouse_entered.bind(true))
	mouse_exited.connect(_on_mouse_entered.bind(false))
	clip_contents = true
	controlled_child = get_children()[0] if get_children().size() > 0 else null
	
	# Don't process input in editor.
	set_process_input(!Engine.is_editor_hint())
	set_process(!Engine.is_editor_hint())
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_controlled_rect()


func update_controlled_rect():
	# Set bounding rect to viewport to keep map layers from culling while
	# partially outside of window.
	if controlled_child.global_position != _pos_last_frame:
		var pos = controlled_child.position
		KuikkaUtils.call_callable_tree_recursive(controlled_child, update_item_rect, [pos])
			
	
	_pos_last_frame = controlled_child.global_position


# Update bounding [Rect2] of [CanvasItem][param item] to given [Vector2][param pos]
func update_item_rect(item: Control, pos: Vector2):
	var rect = item.get_viewport_rect()
	rect.position = pos
	RenderingServer.canvas_item_set_custom_rect(item.get_canvas_item(), true, rect)


func _get_configuration_warnings():
	return "Zoomable Container should have exactly 1 child node to work properly." if get_children().size() != 1 else ""


func _input(event):
	if Engine.is_editor_hint(): 
		return
	# zoom
	if _mouse_in_area:
		if event is InputEventMouseButton:
			event as InputEventMouseButton
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				controlled_child.scale -= Vector2(0.02, 0.02)
				controlled_child.scale.x = clamp(controlled_child.scale.y, 0.5, 10)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				controlled_child.scale += Vector2(0.02, 0.02)
				controlled_child.scale.y = clamp(controlled_child.scale.y, 0.5, 10)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				_mouse_down = event.pressed
		
		if event is InputEventMouseMotion and _mouse_down:
			var move = event.relative
			controlled_child.global_position += move
		
		# Tooltip edits
		tooltip.global_position = get_viewport().get_mouse_position()
		var map_point = tooltip.global_position-texture_rect.global_position
		var height = NAN
		if texture_rect.texture:
			var img = texture_rect.texture.get_image()
			var x =  round(map_point.x/controlled_child.scale.x)
			var y = round(map_point.y/controlled_child.scale.y)
			
			if x < img.get_width() and y < img.get_height():
				height = texture_rect.texture.get_image().get_pixel(x, y).r
		var real_value = height_range.x + (height_range.y-height_range.x) * height
		
		tooltip.text = "H: %f (%d, %d) \n[Normalized: %f] " % [real_value, map_point.x/controlled_child.scale.x, map_point.y/controlled_child.scale.y, height]
		

func _on_mouse_entered(val:bool=false):
	_mouse_in_area = val and visible
	tooltip.visible = val and visible
