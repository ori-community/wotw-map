extends Node2D


@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	animation_player.speed_scale = randf_range(0.9, 1.1)
