extends Node

#My current scene
var current_scene = null
var network = null

#Who I am
var selfID = 0

#Load the network manager and start 
func _ready():
	network = get_node("/root/network_manager")
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

#To change scene
func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()
	
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
		#Set team and nick based on the info we received
		player.get_node("nick").text = network.player_info[p]["nick"]
		#player.set_network_master(str(p))
		get_node("/root/" + current_scene.name + "/players").add_child(player)
		
		print(p)
		print(j)
		
		if (j % 2 == 0):
			player.set_team(global_c.TEAM_A)
		else:
			player.set_team(global_c.TEAM_B)
		j += 1
	
	var ch = get_node("/root/" + current_scene.name + "/players").get_children()
	
	for c in ch:
		print(c.name)
	
	print("!")
	
	current_scene.get_main_player()
	
	#Register that this peer has finished
	network.send_scene_loaded(selfID)



