@tool
extends EditorPlugin

## Main [EditorPlugin] component for Kuikka Terrain Generator
## to add / remove plugin from project.

var singleton_name : String = "KuikkaTerrainGen"
var singleton_script : String = "res://addons/kuikka_terrain_gen/components/terrain_server.gd"

const editor_ui_scene : PackedScene = preload("res://addons/kuikka_terrain_gen/ui/terrain_generator_ui.tscn")

# Main panel ui instance
var _editor_ui : Control


## Add components / enable plugin
func _enter_tree():
	add_autoload_singleton(singleton_name, singleton_script)
	
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
	if _editor_ui:
		_editor_ui.queue_free()


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
