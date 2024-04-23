extends Node

@export var min_val = get_node("../MinValue")
@export var max_val = get_node("../MaxValue")


# Set maximum to same as minimum if minimum becomes bigger
func _on_minvalue_value_changed(value):
	if value > max_val.value:
		max_val.value = value


# Set minimum to same as maximum if maximum becomes smaller
func _on_max_value_value_changed(value):
	if value < min_val.value:
		min_val.value = value
