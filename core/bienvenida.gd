extends Control

const code_digits = 5

#Network manager
var network = null
var manager = null

func _ready():
	
	#Get the network/scene manager
	network = get_node("/root/network_manager")
	manager = get_node("/root/scene_manager")
	
	#And then choose client or server
	if OS.get_name() == "HTML5":
		init_client_screen()
	else:
		init_client_screen()
		#network.make_server()
	

func init_server_screen():
	randomize()
	
	#Show server data
	$background/server.show()
	$background/client.hide()
	
	#Then set text...
	$background/server/data.text = "IP:  "
	
	#Get the array of local IPs
	var ips = IP.get_local_addresses()
	var local_ip = ""
	print(ips)
	#Get the public IP of this computer
	for ip in ips:
		if "127.0" in ip:
			local_ip = ip
	
	#Write it...
	$background/server/data.text += local_ip
	
	#Generate a random game ID
	$background/server/data.text += "\r\nCode:  "
	network.gameID = randi() % 100000
	$background/server/data.text += String(network.gameID )
	
	#Wait for the players
	set_process(true)

func init_client_screen():
	#Show client data
	$background/server.hide()
	$background/client.show()

func _on_clnt_connect_pressed():
	var name = $background/client/name_edit.text
	var code = $background/client/code_edit.text
	var ip = $background/client/ip_edit.text
	
	network.my_info["nick"] = name
	
	if network.connection_request(code, ip) != OK:
		$background/client/status.text = "Error connecting server"
	else:
		$background/client/status.text = "Connected"

#Starts the game
func _on_startgame_pressed():
	network.share_player_info()
	network.load_level("res://core/level.tscn")

#Auxiliary debug stuff
func _on_debug_switch_pressed():
	init_server_screen()
	network.make_server()



