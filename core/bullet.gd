extends Area2D

var bullet_dir = global_c.RIGHT
var sender_team = global_c.TEAM_A

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
		body.damage()
	
	
	queue_free()
	