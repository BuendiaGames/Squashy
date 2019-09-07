extends Node2D

var network = null
var selfID = null
var player = null


#Pause game
func _ready():
	network = get_node("/root/network_manager")
	selfID = get_tree().get_network_unique_id()
	
	set_process(get_tree().is_network_server())
	set_process_input(true)
	get_tree().paused = true

#Who is the player associated to this local machine
func get_main_player():
	if not get_tree().is_network_server():
		player = get_player(selfID)


#If this is the server, then send info to everybody
#TODO: then can process be set to false in clients????
func _process(delta):
	for id in network.player_info:
		var peer = get_player(id)
		peer.send_pos(id)

#Send movement action for the sender id
remote func send_action(sender_id, action):
	var peer = get_player(sender_id)
	peer.current_action = action

#Creates a shoot for the sender
remote func send_shoot(sender_id):
	var peer = get_player(sender_id)
	peer.shoot()

#Capture input
func _input(event):
	
	#Move right
	if event.is_action_pressed("ui_right"):
		player.current_action = global_c.RIGHT
		rpc_id(1, "send_action", selfID, global_c.RIGHT)
	elif event.is_action_released("ui_right") and player.current_action == global_c.RIGHT:
		player.current_action = global_c.IDLE
		rpc_id(1, "send_action", selfID, global_c.IDLE)
	
	#Move left
	if event.is_action_pressed("ui_left"):
		player.current_action = global_c.LEFT
		rpc_id(1, "send_action", selfID, global_c.LEFT)
	elif event.is_action_released("ui_left") and player.current_action == global_c.LEFT:
		player.current_action = global_c.IDLE
		rpc_id(1, "send_action", selfID, global_c.IDLE)
	
	#Jump
	if event.is_action_pressed("ui_up"):
		player.current_action = global_c.JUMP
		rpc_id(1, "send_action", selfID, global_c.JUMP)
	
	#Shoot
	if event.is_action_pressed("shoot"):
		player.shoot()
		#rpc_id(1, "send_shoot", selfID)


func get_player(id):
	return get_node("players/" + str(id))