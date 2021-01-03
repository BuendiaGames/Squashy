extends Node2D

#Player / ID of the local machine
var selfID = null
var localplayer = null


#Points & stats
var points_A
var points_B
var points_per_player = {}

#Flags
var flag_A = null
var flag_B = null

#Camera and respawn constants

const time2spawn = [2.0, 5.0] #In seconds. Time corresponding to each reason.
var camera = null
var time_to_fast = 3.0
var elapsed_time = 0.0
const cameraspeed_slow = 500.0
const cameraspeed_fast = 1500.0
var cameraspeed = cameraspeed_slow

#Pause game
func _ready():
	selfID = get_tree().get_network_unique_id()
	
	get_tree().paused = true
	
	#Create and configure camera
	camera = Camera2D.new()
	camera.zoom = Vector2(0.5, 0.5)
	camera.name = "cam"
	camera.drag_margin_h_enabled = false
	camera.drag_margin_v_enabled = false
	camera.make_current()
	
	
	#Server!
	if selfID == 1: 
		add_child(camera)
		init_points()
		set_process(true)
	else:
		set_process(false)
	
	#Get the flag nodes, will be useful for respawns
	flag_A = get_node("flags/flagA")
	flag_B = get_node("flags/flagB")

#Who is the player associated to this local machine
func get_main_player():
	localplayer = get_node("players/" + str(selfID))
	localplayer.add_child(camera)


#Camera movement
func _process(delta):
	
	if Input.is_action_pressed("ui_up"):
		$cam.position.y -= cameraspeed * delta
		elapsed_time += delta
	elif Input.is_action_pressed("ui_down"):
		$cam.position.y += cameraspeed * delta
		elapsed_time += delta
	elif Input.is_action_pressed("ui_right"):
		$cam.position.x += cameraspeed * delta
		elapsed_time += delta
	elif Input.is_action_pressed("ui_left"):
		$cam.position.x -= cameraspeed * delta
		elapsed_time += delta
	else:
		cameraspeed = cameraspeed_slow
		elapsed_time = 0.0
	
	if (elapsed_time >= time_to_fast):
		cameraspeed = cameraspeed_fast
	



# Points and stats --------------------------------

func init_points():
	points_A = 0
	points_B = 0
	
	for p in network_manager.player_info:
		points_per_player[p] = 0

#When player associated with pid scored, annotate it
func point(pid):
	#PID is string, as it is a node name
	#But in all dicts it is an integer
	pid = int(pid) 
	
	print("Point by " + str(pid))
	points_per_player[pid] += 1
	var pteam = network_manager.player_info[pid]["team"]
	
	if pteam == global_c.TEAM_A:
		points_A += 1
	else:
		points_B += 1


# Respawn --------------------------------------

#Request to start a respawn. This is server-side
func request_respawn(pid, reason):
	rpc("init_respawn", pid)
	rpc_id(int(pid), "start_move_2_base", reason)


#Get the player and hide it. Avoid moving it
remotesync func init_respawn(pid): 

	var player = get_node("players/" + pid)
	player.hide()
	
	#Avoid ANY collision of player while the respawn takes place.
	call_deferred("switch_col_shape", player)

#Activates / Inactivates the collision shape of the player
#Aux function so it can be called on deferred mode
#Col shapes cannot be disabled while busy!
func switch_col_shape(player):
	player.get_node("shape").disabled = not player.get_node("shape").disabled 

remote func start_move_2_base(reason): 
	#I'm going to move the player associated with this client
	var player = localplayer
	
	#This triggers the spawn movement
	player.respawning = true
	
	#Get respawn place
	if player.team == global_c.TEAM_A:
		player.respawn_coords = flag_A.position
	else:
		player.respawn_coords = flag_B.position
	
	#Set the time to respawn
	player.time2respawn = time2spawn[reason]
 
#Make effective the respawn
func make_respawn(pid):
	rpc("respawn", pid)

#The player can play again
remotesync func respawn(pid):
	#Redo what was undone last time!
	var player = get_node("players/" + pid)
	
	#Set life to maximum
	player.life = player.maxlife
	player.scale = Vector2(1,1)
	player.show()
	
	call_deferred("switch_col_shape", player)
