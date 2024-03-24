extends Node
class_name KuikkaUtils

const CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"

# Create simple random [String] of given length.
# NOTE: Has no quarantees for uniqueness. Use some uuid implementation instead.
static func rand_string(length : int):
	var str : String = ""
	
	for i in length:
		str += CHARS[randi() % CHARS.length()]
	
	return str
	
