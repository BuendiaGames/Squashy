extends Node

#This script stores global constants!


#Player possible states

const IDLE = 0
const LEFT = -1
const RIGHT = 1
const JUMP = 2
const NOTHING = 3

const TEAM_A = 0
const TEAM_B = 1

const FL_NORMAL = Vector2(0.0, -1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
