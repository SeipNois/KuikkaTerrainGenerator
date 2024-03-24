class_name KuikkaEditorTab extends KuikkaTerrainGenUI

## [Control] UI Element for generating heightmaps inside Editor tab.


## Editor plugin that has loaded this element.
var editor_plugin: EditorPlugin


func set_editor_plugin(new_plugin: EditorPlugin):
	editor_plugin = new_plugin
