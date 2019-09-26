extends Node2D

var life = 100.0

remotesync var team = global_c.TEAM_A
remotesync var color = global_c.TA_COLOR

func _ready():
	add_to_group("walls")

#Team of this wall
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


#Set the correct position, in front of character, and fixing the height
func set_pos(p, dir):
	position = p
	position.x += dir * 40
	position.y -= 80 #region rect /2

func damage(d):
	rpc("do_damage_net", d)

remotesync func do_damage_net(d):
	life -= d
	if life <= 0:
		queue_free()