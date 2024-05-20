class_name KuikkaConfig extends Node


static func tools_config():
	var cfg = ConfigFile.new()
	cfg.load("res://addons/kuikka_terrain_gen/config/external_tools_config.cfg")
	return cfg
