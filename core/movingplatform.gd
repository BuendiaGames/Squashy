extends KinematicBody2D
#tool 

enum pltypes {Grass, Rock}
export(pltypes) var platform_style setget set_plstyle, get_plstyle 

export(Vector2) var dist_2_move = Vector2(50,0)

const speed = 5.0
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

func _ready():
	forward = true
	
	initial_pos = position
	final_pos = dist_2_move + initial_pos
	target = final_pos
	
	direction = dist_2_move.normalized()
	set_process(true)

func _draw():
	draw_line(position, position + dist_2_move, Color.red, 2.0)

func _process(delta):
	move_and_collide(direction * speed)
	
	if position.distance_squared_to(target) <= 5:
		direction = -direction
		if forward:
			target = initial_pos
		else:
			target = final_pos


