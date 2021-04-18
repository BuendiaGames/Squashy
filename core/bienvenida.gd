extends Control

const code_digits = 5

#Network manager
var network = null
var manager = null

#For random stuff that goes in the background
var rng = RandomNumberGenerator.new()
var bichos_speed = []
var bichos_angsp = []
var bichos_frames = 20
var bichos_maxspd = 200
var bichos_minspd = 40
var bichos_maxang = 4.0
var n_bichos = 12

func _ready():
	
	rng.randomize()
	
	#Get the network/scene manager
	network = network_manager
	manager = scene_manager
	
	#And then choose client or server
	if OS.get_name() == "HTML5":
		init_client_screen()
	else:
		init_client_screen()
		#network.make_server()
	
	#The process controls movement of background...
	create_bichos()
	set_process(true)

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
	#set_process(true)

func clean_player_names():
	$background/server/pl_team1.text = "Blue Team\n"
	$background/server/pl_team2.text = "Red  Team\n"

func add_player_name(id, peer_info):
	var nick = peer_info["nick"]
	var team = peer_info["team"]
	
	var pl_label = Label.new()
	pl_label.text = nick
	
	#TODO ADD CHANGE TEAM CLICK EVENT FOR SERVER
	
	if team == global_c.TEAM_A:
		$background/server/team1.add_child(pl_label)
		#$background/server/pl_team1.text += nick + "\n"
	else:
		$background/server/team2.add_child(pl_label)
		#$background/server/pl_team2.text += nick + "\n"

#Show client data
func init_client_screen():
	$background/server.hide()
	$background/client.show()

#When the button is pressed, connect...
func _on_clnt_connect_pressed():
	
	#Get our data
	var name = $background/client/vbox/name_edit.text
	var code = $background/client/vbox/code_edit.text
	var ip = $background/client/vbox/ip_edit.text
	
	network.my_info["nick"] = name
	
	#Try to connect
	if network.connection_request(code, ip) != OK:
		pop("Connection Error. Please check IP\r\nand connection, or try later.")
	else:
		$background/client.hide()
		$background/server.show()
		$background/server/startgame.hide()
		$background/client/vbox2/clnt_connect.disabled = true
		$background/client/vbox2/debug_switch.disabled = true
		
		$background/client/vbox/ip.hide()
		$background/client/vbox/code.text += str(network.gameID)

func pop(message):
	$background/client/popup.popup(Rect2(100,100,550,200))
	$background/client/popup/poplabel.text = message

#Starts the game
func _on_startgame_pressed():
	network.share_player_info()
	network.load_level("res://scenarios/the_tunnels.tscn")

#Auxiliary debug stuff
func _on_debug_switch_pressed():
	init_server_screen()
	network.make_server()

func create_bichos():
	
	var bicho = null

	
	for n in range(n_bichos):
		bicho = Sprite.new()
		bicho.name = "bicho" + str(n)
		bicho.add_to_group("back_bichos")
		bicho.texture = load("res://graphics/ui/ui-bichejos.png")
		bicho.hframes = bichos_frames
		bicho.frame = rng.randi_range(0,bichos_frames-1)
		#Todo: adjust to viewport size
		var bx = rng.randf_range(0,1024)
		var by = rng.randf_range(0,600)
		bicho.position = Vector2(bx, by)
		
		var speed = rng.randf_range(-bichos_maxspd, bichos_maxspd)
		if abs(speed) <= bichos_minspd:
			if speed < bichos_minspd: speed = bichos_minspd
			else: speed = -bichos_minspd
		
		bichos_speed.append(speed)
		bichos_angsp.append(rng.randf_range(-bichos_maxang, bichos_maxang))
		$background/bichos.add_child(bicho)

func _process(delta):
	
	var bicho = null
	for n in range(n_bichos):
		bicho = get_node("background/bichos/bicho" + str(n))
		bicho.position.x += delta * bichos_speed[n]
		bicho.rotation += delta * bichos_angsp[n] 
		
		if (bicho.position.x < -20 || bicho.position.x > 1044):
			bicho.frame = rng.randi_range(0,bichos_frames-1)
			var speed = rng.randf_range(-bichos_maxspd, bichos_maxspd)
			
			bicho.position.y = rng.randf_range(0,600)
			if speed > 0.0:
				bicho.position.x = -20
				if speed < bichos_minspd: speed = bichos_minspd
			else:
				bicho.position.x = 1044
				if speed > -bichos_minspd: speed = -bichos_minspd
			
			bichos_speed[n] = speed
			bichos_angsp[n] = rng.randf_range(-bichos_maxang, bichos_maxang)
