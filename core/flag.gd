extends Area2D

tool
export(int, "A", "B") var team = 0 setget chooseteam, getteam

#Short for current level
var cur_level = null

#Indicates if someone scored, to avoid checking a collision
#multiple times
var flag_busy = false

#Setter/Getter for team, as it is selected in the editor
#Basically controls color in-editor
func chooseteam(new_team):
	team = new_team
	if team == global_c.TEAM_A:
		$Sprite.modulate = global_c.TA_COLOR
	elif team == global_c.TEAM_B:
		$Sprite.modulate = global_c.TB_COLOR

func getteam():
	return team


#Ready ----------------
func _ready():
	if not Engine.editor_hint:
		cur_level = scene_manager.current_scene

#Give a point to the Squashy reaching the goal

func _on_flag_body_entered(body):
	if not Engine.editor_hint:
		if get_tree().is_network_server():
			if body.is_in_group("players") and not flag_busy:
				if team != body.team:
					flag_busy = true
					#Remember that body name coincides with ID
					cur_level.point(body.name)
					cur_level.request_respawn(body.name, global_c.POINT)
					return 

func _on_flag_body_exited(body):
	if not Engine.editor_hint:
		if get_tree().is_network_server():
			flag_busy = false
