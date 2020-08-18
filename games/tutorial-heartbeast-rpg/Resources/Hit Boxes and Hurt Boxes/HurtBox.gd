extends Area2D

export(bool) var show_hit = true

const HitEffect = preload("res://Resources/Effects/HitEffect.tscn")

func _on_HurtBox_area_entered(area):
	if show_hit:
		var effect = HitEffect.instance()
		var main = get_tree().current_scene
		main.add_child(effect)
		effect.global_position = global_position
