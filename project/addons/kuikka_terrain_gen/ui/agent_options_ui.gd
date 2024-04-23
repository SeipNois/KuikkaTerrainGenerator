class_name AgentOptionsUI extends CenterContainer

enum ValueType {TOKENS, SPEED_MIN, SPEED_MAX, JUMP_TR, GEN_TR, GEN_TYPE}
signal value_changed(value: float, value_type: ValueType, agent: String)

@export var agent_name : String:
	set(val):
		agent_name = val
		if %Title:
			%Title.text = agent_name


func _on_tokens_spin_box_value_changed(value):
	value_changed.emit(value, ValueType.TOKENS, agent_name)


func _on_move_speed_min_spin_box_value_changed(value):
	value_changed.emit(value, ValueType.SPEED_MIN, agent_name)


func _on_move_speed_max_spin_box_value_changed(value):
	value_changed.emit(value, ValueType.SPEED_MAX, agent_name)


func _on_gen_tresh_spin_box_value_changed(value):
	value_changed.emit(value, ValueType.GEN_TR, agent_name)


func _on_jump_spin_box_value_changed(value):
	value_changed.emit(value, ValueType.JUMP_TR, agent_name)


func _on_option_button_item_selected(index):
	value_changed.emit(index, ValueType.GEN_TYPE, agent_name)
