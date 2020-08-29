extends Node2D

signal smell_detected(scent)
signal smell_lost(scent)

func _ready():
	pass # Replace with function body.
	
func _on_area_entered(scent):
	print('entered: ', scent.name)
	emit_signal("smell_detected", scent)

func _on_area_exited(scent):
	print('exited: ', scent.name)
	emit_signal("smell_lost", scent)
