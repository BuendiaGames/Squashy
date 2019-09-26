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
remotesync var dir = global_c.RIGHT
var current_action = global_c.IDLE


#Jump
var yspeed = 0.0
const jumpspeed = 100.0
const g = 100.0
remote var in_air = false
var in_water = false
var water_contact = null

#Actions
var team = global_c.TEAM_A
var bullet_class = null
var wall_class = null


#Vars 
var life = 100.0
var maxlife = 100.0

var minscale = 0.4

var create_clock = 0.0
const create_time = 3.0

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("players")
	update_texture(TEX32) #Set the default texture
	bullet_class = preload("res://core/bullet.tscn")
	wall_class = preload("res://core/barrier.tscn")
	set_process(get_tree().is_network_server())

func _process(delta):
	
	in_air = not is_on_floor()
	
	#Process actions
	if current_action == global_c.LEFT or current_action == global_c.RIGHT:
		rpc_unreliable("look_dir", current_action)
		vel.x = speed * current_action
		if not in_air:
			rpc_unreliable("change_anim", "run")
	elif current_action == global_c.JUMP:
		vel.y = -jumpspeed
		in_air = true
		rpc("change_anim", "jump_start")
		set_action(global_c.NOTHING)
	elif current_action == global_c.IDLE:
		vel.x = 0.0
		create_clock = 0.0 #Reset the clock for wall creation
		rpc("change_anim", "idle")
	elif current_action == global_c.CHARGE:
		vel.x = 0.0
		create_clock += delta
		rpc_unreliable("change_anim", "create")
		#Build a wall or conquest water, depending on situation
		if create_clock > create_time:
			if not in_water:
				build()
			else:
				water_contact.set_team(team)
			set_action(global_c.IDLE)
	
	if in_air:
		vel.y += delta * g
		if vel.y > 5 * delta * g:
			rpc_unreliable("change_anim", "jump_air")
	else:
		if vel.y > 5 * delta * g:
			rpc("change_anim", "jump_landing")
		vel.y = 0
	
	move_and_slide(vel, global_c.FL_NORMAL)
	

#Changes where am I looking at in every peer
remotesync func look_dir(d):
	dir = d
	$sprite.flip_h = dir == global_c.RIGHT


#--------------------------------------------------
# Create bullets, walls and conquest water
#--------------------------------------------------

#Shoot a bullet in every peer
func shoot():
	damage(5.0)
	rpc("change_anim", "shoot")
	rpc("create_bullet")

#Instance a bullet and set its properties
remotesync func create_bullet():
	
	var bullet = bullet_class.instance()
	bullet.set_dir(dir)
	bullet.set_team(team)
	bullet.position = position
	bullet.position.x += dir * 30
	scene_manager.current_scene.get_node("bullets").add_child(bullet)

func build():
	rpc("create_wall")

remotesync func create_wall():
	var wall = wall_class.instance()
	wall.set_team(team)
	wall.set_pos(position, dir)
	scene_manager.current_scene.get_node("walls").add_child(wall)

#--------------------------------------------------
# Damage or recover the individual over the network
#--------------------------------------------------
func damage(d):
	rpc("do_damage_net", d)

remotesync func do_damage_net(d):
	life -= d
	scale = Vector2(1,1) * (minscale + (1.0-minscale) * life / maxlife)
	if life <= 0.0:
		network_manager.disconnect_from_server(int(self.name))

func recover(r):
	rpc("do_recov_net", r)

remotesync func do_recov_net(r):
	life = max(life + r, maxlife)
	print(life)
	scale = Vector2(1,1) * (minscale + (1.0-minscale) * life / maxlife)

#Configure the team and set the adequate recolor!
func set_team(new_team):
	rpc("configure_team", new_team)

remotesync func configure_team(new_team):
	team = new_team
	$sprite.material = preload("res://core/red_material.tres")

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


#Animation controller over the network!
remotesync func change_anim(new_anim):
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