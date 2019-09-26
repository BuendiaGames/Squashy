extends Area2D

var bullet_dir = global_c.RIGHT
var sender_team = global_c.TEAM_A

var damage = 20

const speed = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)
	pass

#Who created this bullet
func set_team(team):
	sender_team = team

func set_dir(dir):
	bullet_dir = dir


#Move bullet
func _process(delta):
	
	position.x += bullet_dir * speed * delta
	

#Damage the individual
func _on_bullet_body_entered(body):
	
	#TODO add damage/recover depending on team
	if body.is_in_group("players"):
		if sender_team != body.team:
			body.damage(20.0)
		else:
			body.recover(20.0)
	elif body.is_in_group("walls"):
		body.damage(damage)
	
	queue_free()
	
