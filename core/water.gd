extends Area2D

remotesync var team = global_c.TEAM_0
remotesync var color = global_c.TA_COLOR

func _ready():
	pass 

func set_team(new_team):
	if new_team == global_c.TEAM_A:
		color = global_c.TA_COLOR
	else:
		color = global_c.TB_COLOR
	
	rset("team", new_team)
	rpc("change_color", color)

#Change the color for all peers
remotesync func change_color(c):
	color = c
	$sprite.modulate = c
	$sprite.modulate.a = 0.5


#When you enter the water, and are a player, 
#register water inside player. Then recover if it is our team
func _on_water_body_entered(body):
	if get_tree().is_network_server():
		if body.is_in_group("players"): 
			body.enter_water(team, name)

#Make information about water vanish
func _on_water_body_exited(body):
	if get_tree().is_network_server():
		if body.is_in_group("players"):
			body.exit_water()
