extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)

func _process(delta):
	var elapsed_time = scene_manager.current_scene.get_time_left()
	var minutes = floor(elapsed_time/60)
	var seconds = elapsed_time - 60*minutes
	
	
	$time.text = "%s:%.1f" % [minutes,seconds]

func update_points(team, points):
	if team == global_c.TEAM_A:
		$points/blue.text = str(points)
	else:
		$points/red.text = str(points)
