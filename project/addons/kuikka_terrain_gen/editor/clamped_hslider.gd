extends SpinBox

## Clamp SpinBox range to linked minimum and maximum values.

func _on_minvalue_value_changed(val):
	min_value = val


func _on_max_value_value_changed(val):
	max_value = val


func _on_min_value_value_changed(value):
	pass # Replace with function body.
