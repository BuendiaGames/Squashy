extends KinematicBody2D


#Player code. Player is processed in server, receiving 
#all the input from the "level" scene; this is because only
#one squashy is to be controlled from player -others are from
#different peers. 
#Then, all rpc calls are meant to SEND information to CLIENTS from server.

#Horizontal movement
const speed = 20
var vel = Vector2(0.0, 0.0)
var dir = global_c.RIGHT
var current_action = global_c.IDLE


#Jump
var yspeed = 0.0
const jumpspeed = 100.0
const g = 100.0
remote var in_air = false


#Actions
remote var team = global_c.TEAM_A
var bullet_class = null

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("players")
	bullet_class = preload("res://core/bullet.tscn")
	set_process(get_tree().is_network_server())

func _process(delta):
	
	#Process actions
	if current_action == global_c.LEFT or current_action == global_c.RIGHT:
		dir = current_action
		vel.x = speed * current_action
		move_and_slide(vel, global_c.FL_NORMAL)
	elif current_action == global_c.JUMP:
		vel.y = -jumpspeed
		in_air = true
		set_action(global_c.IDLE)
	elif current_action == global_c.IDLE:
		vel.x = 0.0
	
	if in_air:
		vel.y += delta * g
		move_and_slide(vel, global_c.FL_NORMAL)
		#TODO: check floor collision
	else:
		vel.y = 0.0
	
	in_air = not is_on_floor()

#Shoot a bullet in every peer
func shoot():
	rpc("create_bullet")

#Instance a bullet and set its properties
remotesync func create_bullet():
	
	var bullet = bullet_class.instance()
	bullet.set_dir(dir)
	bullet.set_team(team)
	bullet.position = position
	bullet.position.x += dir * 50
	scene_manager.current_scene.get_node("bullets").add_child(bullet)

#Damage the individual
func damage():
	rpc("do_damage_net")

remotesync func do_damage_net():
	print("Damaged!")

#TODO: set color according to team
func set_team(new_team):
	rset("team", new_team)

#This pair of functions change the current action.
#It does it locally (in server) and remotely (in clients)
func set_action(action):
	rpc("set_player_action", action)

remotesync func set_player_action(action):
	current_action = action

#This pair of functions update the state of the player
func send_pos(id):
	rset_unreliable_id(id, "in_air", in_air)
	rpc_unreliable_id(id, "set_pos", position)

remote func set_pos(new_pos):
	position = new_pos