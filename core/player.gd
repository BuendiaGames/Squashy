extends KinematicBody2D


#Player code. Player sends its info to all the other
#peers, updating its info to the network.

var should_process = false

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
const speed = 110.0
var vel = Vector2(0.0, 0.0)
remotesync var dir = global_c.RIGHT


#Jump
const jumpspeed = 500.0
const g = 1000.0
remote var in_air = false
var in_water = false
var water_contact = null

#Classes
var team = global_c.TEAM_A
var bullet_class = null
var wall_class = null


#Vars 
var life = 100.0
var maxlife = 100.0
var minscale = 0.4

#Actions
var create_clock = 0.0
const create_time = 3.0
var build_finished = false

#Respawn
var respawning = false
var respawn_coords = null
var time2respawn = 0.0
var spawn_move_speed = 200.0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	add_to_group("players")
	update_texture(TEX32) #Set the default texture
	bullet_class = preload("res://core/bullet.tscn")
	wall_class = preload("res://core/barrier.tscn")
	set_process(false)
	set_physics_process(should_process)



func _physics_process(delta):
	
	if not respawning:
		if $anim.current_animation != "boom":
			player_controlled(delta)
		else:
			print("kaboom")
	else:
		print($anim.current_animation)
		move_to_respawn(delta)
		print($sprite.frame)
	

func player_controlled(delta):
	
	in_air = not is_on_floor()
	
	#Snap to the floor 10 pixels when we are 
	#not jumping, to avoid jiggly platforms
	var snap = Vector2(0.0, 10)
	
	#Process actions
	if Input.is_action_pressed("ui_left"):
		rpc_unreliable("look_dir", global_c.LEFT)
		vel.x = -speed
		if not in_air:
			rpc_unreliable("change_anim", "run")
	elif Input.is_action_pressed("ui_right"):
		rpc_unreliable("look_dir", global_c.RIGHT)
		vel.x = speed
		if not in_air:
			rpc_unreliable("change_anim", "run")
	else:
		vel.x = 0.0
		if not in_air:
			rpc_unreliable("change_anim", "idle")
	
	#Process jump
	if Input.is_action_just_pressed("ui_up"):
		vel.y = -jumpspeed
		in_air = true
		snap.y = 0 #Free the snap 
		rpc("change_anim", "jump_start")
	elif Input.is_action_pressed("ui_down") and not build_finished:
		vel.x = 0.0
		create_clock += delta
		rpc_unreliable("change_anim", "create")
		#Build a wall or conquest water, depending on situation
		if create_clock > create_time:
			build_finished = true
			if not in_water:
				build()
			else:
				water_contact.set_team(team)
	else:
		create_clock = 0.0
		build_finished = 0.0
	
	#Falling logic
	if in_air:
		vel.y += delta * g
		if vel.y > 5 * delta * g:
				rpc_unreliable("change_anim", "jump_air")
	else:
		if vel.y > 5 * delta * g:
			rpc("change_anim", "jump_landing")
		vel.y = get_floor_velocity().y
	
	
	#Attack
	if Input.is_action_just_pressed("shoot"):
		init_shoot()
	elif Input.is_action_just_pressed("boom"):
		init_boom()
	
	
	#Move and update peers
	move_and_slide_with_snap(vel, snap, global_c.FL_NORMAL)
	send_pos()


#Move our player to respawn it 
func move_to_respawn(delta):
	#Compute normalize vector to flag and move
	dir = position.direction_to(respawn_coords)
	var dist2 = position.distance_squared_to(respawn_coords)
	
	if (dist2 > 10.0):
		position += spawn_move_speed * delta * dir
		send_pos()
	elif (time2respawn <= 0.0):
		respawning = false
		scene_manager.current_scene.make_respawn(self.name)
	
	time2respawn -= delta
	


#--------------------------------------------------
# Position and movement
#--------------------------------------------------

#This pair of functions update the state of the player
func send_pos():
	rset_unreliable("in_air", in_air)
	rpc_unreliable("set_pos", position)

#Update position over the network
remotesync func set_pos(new_pos):
	position = new_pos

#Animation controller over the network!
remotesync func change_anim(new_anim):
	
	if $anim.current_animation == "shoot":
		return
	
	if anim != new_anim:
		anim = new_anim
		$anim.play(anim)

#Changes where am I looking at in every peer
remotesync func look_dir(d):
	dir = d
	$sprite.flip_h = dir == global_c.RIGHT


#--------------------------------------------------
# Create bullets, walls and conquest water
#--------------------------------------------------

#Prepare to shoot, creating a bullet
#triggered by animation_finished

func init_shoot():
	rpc("change_anim", "shoot") 

#Shoot a bullet. This is executed in every peer, since the 
#change of anim that triggers this was called on the network
func shoot():
	create_bullet(Vector2(dir, 0.0), false)
	damage(5.0)

#Give the order to start exploding, creating explosion
#at animation_finished
func init_boom():
	rpc("update_texture", TEX50)
	rpc("change_anim", "boom")


#Just explode after animation finishes. This is called
#only in server, in order to generate exactly the same random
#bullets for all peers
func boom():
	if get_tree().is_network_server():
		var nbullets = int(life / 10.0)
		var randir = Vector2.ZERO
		for j in range(nbullets):
			randir = Vector2(2*randf()-1, 2*randf()-1)
			rpc("create_bullet", randir / randir.length_squared(), true)
	
		damage(maxlife)


#Instance a bullet and set its properties
remotesync func create_bullet(direction, is_explo):
	var bullet = bullet_class.instance()
	bullet.is_explosion(is_explo)
	bullet.set_dir(direction)
	bullet.set_team(team)
	bullet.position = position
	bullet.position.x += dir*10
	bullet.position.y += 10
	scene_manager.current_scene.get_node("bullets").add_child(bullet)



#Wall creation
func build():
	rpc("create_wall")
	damage(20.0)


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
	
	#If life is < 0, let's start the respawn!
	if life <= 0.0:
		print("I died: " + self.name)
		if get_tree().is_network_server():
			scene_manager.current_scene.request_respawn(self.name, global_c.DEAD)



func recover(r):
	rpc("do_recov_net", r)

remotesync func do_recov_net(r):
	life = max(life + r, maxlife)
	scale = Vector2(1,1) * (minscale + (1.0-minscale) * life / maxlife)


func enter_water(water_team, water_name):
	rpc("in_water_net", water_name)
	
	if team == water_team:
		recover(0.001)

func exit_water():
	rpc("out_water_net")

remotesync func in_water_net(water_name):
	in_water = true
	water_contact = scene_manager.current_scene.get_node("water/" + water_name)

remotesync func out_water_net():
	in_water = false
	water_contact = null

#--------------------------------------------------
# Team configuration
#--------------------------------------------------

#Set correct texture and animation properties
remotesync func update_texture(tex):
	if (tex == TEX32):
		$sprite.texture = tex_iguales
		$sprite.hframes = HF_32
		$sprite.vframes = VF_32
	else:
		$sprite.texture = tex_grandes
		$sprite.hframes = HF_50
		$sprite.vframes = VF_50

#Configure the team and set the adequate recolor!
func set_team(new_team):
	team = new_team
	
	#Set info and request to update it for everybody
	network_manager.my_info["team"] = team
	network_manager.request_update_info()
	
	if (team == global_c.TEAM_B):
		set_collision_mask_bit(2, true)
		$sprite.material = preload("res://core/red_material.tres")
	else:
		set_collision_mask_bit(1, true) #Barrier detection
		$sprite.material = null


func _on_player_tree_exiting():
	print("Deleted node! " + self.name) 
	network_manager.disconnect_from_server(int(self.name))
	pass

func _on_player_tree_exited():
	pass
