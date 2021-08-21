extends Node

#My current scene
var current_scene = null
var network = null

#Who I am
var selfID = 0

#Load the network manager and start 
func _ready():
	network = network_manager
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

#To change scene
func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()
	
	#We are not anymore in lobby
	network.in_lobby = false
	
	# Load the new scene and get the player
	var s = ResourceLoader.load(path)
	var playerscene = preload("res://core/player.tscn")
	
	# Instance the new scene.
	current_scene = s.instance()
	
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)
	
	selfID = get_tree().get_network_unique_id()
	
	#Load players
	var j = 0
	for p in network.player_info:
		var player = playerscene.instance()
		player.name = str(p)
		player.position = Vector2(100.0 + 20*j, 100.0)
		player.should_process = p == selfID and not get_tree().is_network_server()
		
		#Set team and nick based on the info we received
		player.get_node("nick").text = network.player_info[p]["nick"]
		
		get_node("/root/" + current_scene.name + "/players").add_child(player)
		
		if (j % 2 == 0):
			player.set_team(global_c.TEAM_A)
		else:
			player.set_team(global_c.TEAM_B)
		j += 1
	
	var ch = get_node("/root/" + current_scene.name + "/players").get_children()
	
	for c in ch:
		print(c.name)
	
	print("!")
	
	if not get_tree().is_network_server():
		current_scene.get_main_player()
	
	#Register that this peer has finished
	network.send_scene_loaded(selfID)

func politely_ask_go_to_menu():
	
	for id in network.player_info:
		print("estoy mandando a su casa al id " + str(id))
		rpc_id(id, "goto_menu")

remote func goto_menu():
	call_deferred("_deferred_goto_menu")

remote func _deferred_goto_menu():
	
	print("yendo al menu")
	
	# It is now safe to remove the current scene
	current_scene.free()
	
	# Load the menu
	var s = load("res://core/bienvenida.tscn")
	
	# Instance the menu
	current_scene = s.instance()
	
	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)
	
	#Tell the server that I am in menu
	if selfID != 1 and get_tree().network_peer != null:
		rpc_id(1, "confirm_in_menu", selfID)

#Server: once all you are in menu, close connection and change to server
remote func confirm_in_menu(id):
	network.peers_ready.append(id)
	if len(network.peers_ready) == len(network.player_info.keys()):
		for id in network.player_info:
			print("estoy mandando a su casa al id " + str(id))
			network.disconnect_from_server(id)
		
		network.clear()
		get_tree().set_network_peer(null)
		
		#Reset network
		call_deferred("_deferred_goto_menu")
