extends ScrollContainer

@export var line_color : Color = Color.LIGHT_SLATE_GRAY

# Called when the node enters the scene tree for the first time.
func _ready():
	_draw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _draw():
	var rect = get_rect()
	
	draw_line(rect.position, rect.position+Vector2(rect.size.x, 0), line_color)
	draw_line(rect.position, rect.position+Vector2(0, rect.size.y), line_color)
	draw_line(rect.position+Vector2(0, rect.size.y), rect.position+rect.size, line_color)
	draw_line(rect.position+Vector2(rect.size.x, 0), rect.position+rect.size, line_color)
