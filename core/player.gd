extends KinematicBody2D


#Player code. Player is processed in server, receiving 
#all the input from the "level" scene; this is because only
#one squashy is to be controlled from player -others are from
#different peers. 
#Then, all rpc calls are meant to SEND information to CLIENTS from server.

#Animation setup
const VF_32 = 5 #VFrames of the 32x32 image
const HF_32 = 4 #HFrames of the 32x32 image...
const VF_50 = 2
const HF_50 = 5

const TEX32 = 0 #Tex identifier
const TEX50 = 1

#The textures themselves
const tex_iguales = preload("res://graphics/character/sheet_iguales.png")
const tex_grandes = preload("res://graphics/character/spritesheet_grandes.png")

var anim = "idle"

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
	update_texture(TEX32) #Set the default texture
	bullet_class = preload("res://core/bullet.tscn")
	set_process(get_tree().is_network_server())

func _process(delta):
	
	in_air = not is_on_floor()
	
	#Process actions
	if current_action == global_c.LEFT or current_action == global_c.RIGHT:
		dir = current_action
		vel.x = speed * current_action
		$sprite.flip_h = dir == global_c.RIGHT
		if not in_air:
			change_anim("run")
	elif current_action == global_c.JUMP:
		vel.y = -jumpspeed
		in_air = true
		change_anim("jump_start")
		set_action(global_c.NOTHING)
	elif current_action == global_c.IDLE:
		vel.x = 0.0
		change_anim("idle")
	
	if in_air:
		vel.y += delta * g
		if vel.y > 5 * delta * g:
			change_anim("jump_air")
	else:
		if vel.y > 5 * delta * g:
			change_anim("jump_landing")
		vel.y = 0
	
	move_and_slide(vel, global_c.FL_NORMAL)
	


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


#Animation controller
func change_anim(new_anim):
	print(anim)
	print(new_anim)
	if anim != new_anim:
		anim = new_anim
		$anim.play(anim)

#Set correct texture and animation properties
func update_texture(tex):
	if (tex == TEX32):
		$sprite.texture = tex_iguales
		$sprite.hframes = HF_32
		$sprite.vframes = VF_32
	else:
		$sprite.texture = tex_grandes
		$sprite.hframes = HF_50
		$sprite.vframes = VF_50