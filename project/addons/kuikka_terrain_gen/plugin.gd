@tool
extends EditorPlugin

## Main [EditorPlugin] component for Kuikka Terrain Generator
## to add / remove plugin from project.

var singleton_name : String = "KuikkaTerrainGen"
var singleton_script : String = "res://addons/kuikka_terrain_gen/components/terrain_server.tscn"

var timer_singleton_name : String = "KuikkaTimer"
var timer_singleton_script : String = "res://addons/kuikka_terrain_gen/util/global_timer.tscn"

var img_singleton_name : String = "KuikkaImgUtil"
var img_singleton_script : String = "res://addons/kuikka_terrain_gen/util/image_utils.tscn"

const editor_ui_scene : PackedScene = preload("res://addons/kuikka_terrain_gen/ui/terrain_generator_ui.tscn")

# Main panel ui instance
var _editor_ui : Control


## Add components / enable plugin
func _enter_tree():
	add_autoload_singleton(singleton_name, singleton_script)
	add_autoload_singleton(timer_singleton_name, timer_singleton_script)
	add_autoload_singleton(img_singleton_name, img_singleton_script)
	generate_settings()
	
	if Engine.is_editor_hint():
		# FIXME: Implement better alignment in main screen for UI.
		# disabled for now.
		#_editor_ui = editor_ui_scene.instantiate()
		#_editor_ui.name = "TerrainGen"
		#_editor_ui.set_editor_plugin(self)
		#get_editor_interface().get_editor_main_screen().add_child(_editor_ui)
		#_make_visible(false)
		pass
		
## Remove components / disable plugin
func _exit_tree():
	remove_autoload_singleton(singleton_name)
	remove_autoload_singleton(timer_singleton_name)
	remove_autoload_singleton(img_singleton_name)
	if _editor_ui:
		_editor_ui.queue_free()
	clear_settings()


func _has_main_screen():
	# return true
	return false


func _make_visible(visible):
	if _editor_ui:
		_editor_ui.visible = visible


func _get_plugin_name():
	return "Kuikka Terrain Generator"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")


## Generate settings for terrain generator plugin
func generate_settings():
	add_custom_project_setting("kuikka_terrain_gen/gdal_path", "", 4, PROPERTY_HINT_FILE, "Directory path to gdal executables")
	add_custom_project_setting("kuikka_terrain_gen/image_magick_path", "", 4, PROPERTY_HINT_FILE, "File path to ImageMagick executable executables")
	
	
	var error = ProjectSettings.save()
	if error: printerr("Error saving project settings: ", error)

func add_custom_project_setting(name: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:

	if ProjectSettings.has_setting(name): return

	var setting_info: Dictionary = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}

	ProjectSettings.set_setting(name, default_value)
	ProjectSettings.add_property_info(setting_info)
	ProjectSettings.set_initial_value(name, default_value)


func clear_settings():
	remove_custom_project_setting("kuikka_terrain_gen/gdal_path")
	remove_custom_project_setting("kuikka_terrain_gen/image_magick_path")
	
	var error = ProjectSettings.save()
	if error: printerr("Error saving project settings: ", error)

func remove_custom_project_setting(name: String):
	if ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, null)
