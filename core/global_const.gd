extends Node

#This script stores global constants!


#Player possible states
const IDLE = 0
const LEFT = -1
const RIGHT = 1
const JUMP = 2
const CHARGE = 3
const NOTHING = 4

#Teams
const TEAM_A = 0
const TEAM_B = 1
const TEAM_0 = 2

const TA_COLOR = Color("#59ffff")
const TB_COLOR = Color("#fa7c16")

#Floor normal
const FL_NORMAL = Vector2(0.0, -1.0)

#Reasons to respawn
const POINT = 0
const DEAD = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
