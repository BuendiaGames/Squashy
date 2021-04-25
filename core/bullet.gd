extends Area2D

var bullet_dir = global_c.RIGHT
var sender_team = global_c.TEAM_A

var damage = 10.0

var dmg_mult_exp = 5.0
var spd_mult_exp = 3.0

var speed = 250

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)
	pass

#Who created this bullet
func set_team(team):
	sender_team = team
	
	if (team == global_c.TEAM_B):
		set_collision_mask_bit(2, true)
		$sprite.material = preload("res://core/red_material.tres")
	else:
		set_collision_mask_bit(1, true)
		$sprite.material = null

#Set direction of this bullet
func set_dir(dir):
	bullet_dir = dir

#Increase damage for bullets coming from explosion
func is_explosion(explo):
	if explo:
		damage *= dmg_mult_exp
		speed *=  spd_mult_exp

#Move bullet
func _process(delta):
	position += bullet_dir * speed * delta
	


#Damage or recover depending on team
#COLLISION DETECTION IS DONE SERVER-SIDE
#Side node: after damage, body MIGHT be free'd so return
#is used after it in order to avoid calling a second
#body.is_in_group which would result in NULL evaluation!
func _on_bullet_body_entered(body):
	
	if get_tree().is_network_server():
		if body.is_in_group("players"):
			if sender_team != body.team:
				body.damage(damage)
				rpc("free_bullet")
				return 
			else:
				body.recover(10.0)
		elif body.is_in_group("walls"):
			#Damage wall only if it not our team
			if sender_team != body.team:
				body.damage(damage)
				rpc("free_bullet")
				return
		elif body.is_in_group("bullets"):
			#Delete two bullets of different teams that collide in-air
			if sender_team != body.team:
				rpc("free_bullet")
				return

remotesync func free_bullet():
	queue_free()
