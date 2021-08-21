extends StaticBody2D

var life = 100.0

remotesync var team = global_c.TEAM_A
remotesync var color = global_c.TA_COLOR

func _ready():
	add_to_group("walls")

#Team of this wall
func set_team(new_team):
	
	#Delete wall from collision layer 0, where players lives
	set_collision_layer_bit(0, false)
	set_collision_mask_bit(0, false)
	
	#Assign it to its own CL to make it solid only to enemies
	if new_team == global_c.TEAM_A:
		set_collision_layer_bit(2, true)
		color = global_c.TA_COLOR
	else:
		set_collision_layer_bit(1, true)
		color = global_c.TB_COLOR
	
	team = new_team

#Set the correct position, in front of character, and fixing the height
func set_pos(p, dir):
	position = p
	position.x += dir * 40
	position.y -= 60 #region rect /2

#Wall damage
func damage(d):
	rpc("do_damage_net", d)

#Inform peers about wall damage
remotesync func do_damage_net(d):
	life -= d
	if life <= 0:
		queue_free()
