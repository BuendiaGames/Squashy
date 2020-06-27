extends Node

# --- GENERAL SERVER VARS -------------------------------

#This is the password to join the game and the server address
var gameID = null
var server_ip = ""

#Our peer 
var peer = null

#Information about all peers
remote var player_info = {}


#Info of each peer. Fields:
#nick: player nick
#team: current team
var my_info = {"nick": "", "team":0} 

#Maximum number of players allowed in the game
const MAX_PLAYERS = 4

#Port of the server
const SERVER_PORT = 5000

# --- IN-GAME VARS -------------------------------------


var peers_ready = []

func _ready():
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connection_ok")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_server_disconnection")

#Check if our gameID is the same as the server ID
master func check_game_id(gid, peer_info):
	
	var id = get_tree().get_rpc_sender_id()
	print(id)
	
	if int(gameID) == int(gid):
		print("Good connection")
		player_info[id] = peer_info #For now, only NICK is inside
	else:
		print("Bad pass")
		#get_tree().network_peer.disconnect_peer(id, true)
		disconnect_from_server(id)


#Set up the server
func make_server():
	var err = null
	
	#Create a server and add a peer to it.
	#Also check server was created succesfully
	peer = NetworkedMultiplayerENet.new()
	err = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if err != OK:
		print("ERROR CREATING SERVER")
	else:
		get_tree().set_network_peer(peer)
		print("conectado :D")
		#In case it was, connect it


#Request connection with the server. Once connected, 
#the code will be validated with the one stored at server
func connection_request(code, ip):
	var err
	
	server_ip = ip.strip_edges()
	peer = NetworkedMultiplayerENet.new()  
	err = peer.create_client(server_ip, SERVER_PORT)
	
	if err != OK:
		print("ERROR CONNECTING CLIENT")
	else:
		get_tree().set_network_peer(peer)
		gameID = code.strip_edges()
	return err

#Terminates the connection from server
func disconnect_from_server(id):
	
	if get_tree().is_network_server():
		get_tree().network_peer.disconnect_peer(id, true)
		print("here")
	



# ---------------------------------------------------- #
# Lobby / Connection events
# ---------------------------------------------------- #

func _player_connected(id):
	print("hi " + String(id))
	#If I am not the server, then I send my GID to the server
	#in order to validate it
	#if not get_tree().is_network_server():
	#	print("Sending id to server") 
	#	rpc_id(1, "check_game_id", gameID, my_info)
	

func _player_disconnected(id):
	
	#Erase information about this player
	player_info.erase(id)
	print("Bye " + str(id))

#Validate GID with the one stored at server
func _connection_ok():
	print("client connected ok")
	rpc_id(1, "check_game_id", gameID, my_info)

#If connection fails or the server kicks us, simply stop networking
func _connection_failed():
	print("connection failure")
	get_tree().set_network_peer(null)

func _on_server_disconnection():
	print("Disconnected from server")
	get_tree().set_network_peer(null)

# ---------------------------------------------------- #
# Game start synchro
# ---------------------------------------------------- #

#Set the player info for everybody
remote func share_player_info():
	rset("player_info", player_info)
	print("Sending info to players from server")
	print(player_info)

#Send a request to update info to server
func request_update_info():
	if not get_tree().is_network_server():
		rpc_id(1, "update_info", my_info)
	

#Server answers with new info to all peers
remote func update_info(new_info):
	#Should be always true due to rpc_id=1, but double-check it
	var id = get_tree().get_rpc_sender_id()
	print("Request from " + str(id) + ": change player_info to")
	print(new_info)
	player_info[id] = new_info
	print(player_info[id])
	share_player_info()


#Load a new scene, leaving it in pause
func load_level(path):
	rpc("load_level_peer", path)

remotesync func load_level_peer(path):
	scene_manager.goto_scene(path)

#Let the peer inform that he loaded the scene.
func send_scene_loaded(selfID):
	if not get_tree().is_network_server():
		rpc_id(1, "peer_scene_loaded", selfID)
	else:
		peer_scene_loaded(1) #Avoid autocall with rpcid

mastersync func peer_scene_loaded(peer_id):
	print("Peer " + str(peer_id) + " ready")
	
	peers_ready.append(peer_id)
	
	
	#Check that all players + server are connected
	if len(peers_ready) == len(player_info.keys())+1:
		rpc("start_game")

#Let the game start
remotesync func start_game():
	print("Game ready to start!")
	get_tree().paused = false



