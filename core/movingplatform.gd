tool
extends KinematicBody2D
 

enum pltypes {Grass, Rock}
export(pltypes) var platform_style setget set_plstyle, get_plstyle 

export(Vector2) var dist_2_move = Vector2(50,0) setget set_d2m, get_d2m

const speed = 50.0
var initial_pos
var final_pos
var target
var forward
var direction

func set_plstyle(plstyle):
	platform_style = plstyle
	match plstyle:
		pltypes.Grass:
			$pltex.region_rect = Rect2(112, 0, 48, 16)
		pltypes.Rock:
			$pltex.region_rect = Rect2(112, 32, 48, 16)

func get_plstyle():
	return platform_style

func set_d2m(distance):
	#Check to avoid problems with vector (0,0)
	if dist_2_move.length_squared() <= 0.001:
		dist_2_move = Vector2(50, 0.0)
	else:
		#Set and draw
		dist_2_move = distance
		update()


func get_d2m():
	return dist_2_move


func _ready():
	forward = true
	
	initial_pos = position
	final_pos = dist_2_move + initial_pos
	target = final_pos
	
	
	direction = dist_2_move.normalized()
	
	if Engine.editor_hint:
		update()
		set_process(false)
	else:
		set_process(true)

func _process(delta):
	position += delta * direction * speed
	
	if position.distance_squared_to(target) <= 5:
		direction = -direction
		if forward:
			target = initial_pos
		else:
			target = final_pos
		forward = not forward

func _draw():
	if Engine.editor_hint:
		draw_line(Vector2.ZERO, dist_2_move, Color.red, 2.0)


