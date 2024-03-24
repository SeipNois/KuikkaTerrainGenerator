class_name KuikkaLakeParameters extends KuikkaAgentParameters

## Generation parameters for [KuikkaLakeAgent]

## Length of agent movement in pixels
@export var move_speed : Vector2 = Vector2(6, 10)
## Sway of changing direction of lake agent movement
@export var direction_sway : float = PI/2

## Treshold at which agent will seek new starting point.
@export_range(0, 1) var jump_treshold: float = 0.1

## Maximum height at which lakes will be generated.
@export_range(0, 1) var generation_treshold : float = 0.8

