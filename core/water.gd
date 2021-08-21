extends Area2D

func _ready():
	pass 

#When you enter the water, and are a player, 
#register water inside player. Then recover if it is our team
func _on_water_body_entered(body):
	if get_tree().is_network_server():
		if body.is_in_group("players"): 
			body.enter_water(name)

#Make information about water vanish
func _on_water_body_exited(body):
	if get_tree().network_peer != null:
		if get_tree().is_network_server():
			if body.is_in_group("players"):
				body.exit_water()
