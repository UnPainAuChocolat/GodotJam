extends CharacterBody3D

@export var speed = 5.0
@export var jump_velocity = 5.0
@export var gravity = 3.7
@export var mouse_sens = 0.005

@onready var head = $Head
@onready var light = $Head/Flashlight
@onready var interact = $Head/Interaction

var twist_input = 0.0
var pitch_input = 0.0
var light_state = false
var start_time = 0.0
var list_time = []
var index = 0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		twist_input -= event.screen_relative.x * mouse_sens
		pitch_input -= event.screen_relative.y * mouse_sens
		pitch_input = clamp(pitch_input, -85, 85)

func handle_flashlight():
	if Input.is_action_just_pressed("flashlight"):
		start_time = Time.get_ticks_msec()
		light_state = true
	elif Input.is_action_just_released("flashlight"):
		var current_time = Time.get_ticks_msec() - start_time
		list_time.append(current_time)
		index = 0
		print(list_time)
		light_state = false
	if light_state == true:
		light.show()
	elif light_state == false:
		light.hide()

func verify_patern(patern: String):
	var res = false
	for element in list_time:
		if (index >= patern.length()):
			break
		elif (patern[index] == '.') and element <= 400:
			res = true
			index = index + 1
		elif (patern[index] == '-' and element > 400):
			res = true
			index = index + 1
		else:
			res = false
			index = 0
	return res and index == (patern.length())

func _physics_process(delta: float) -> void:
	handle_flashlight()
	handle_interaction()
	
	#eviter que la liste soit trop grande
	if list_time.size() >= 5:
		list_time.pop_front()
	
	#mouvement de la camera
	var current_q = head.basis.get_rotation_quaternion()
	var twist_q = Quaternion(Vector3.UP, deg_to_rad(twist_input))
	var pitch_q = Quaternion(Vector3.RIGHT, deg_to_rad(pitch_input))
	var smoothed_q = current_q.slerp(twist_q * pitch_q, delta * 20.0)
	head.basis = Basis(smoothed_q)
	
	#mouvement du joueur
	velocity.y += -gravity * delta
	var input = Input.get_vector("left", "right", "forward", "backward")
	var movement_dir = head.transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed
	
	move_and_slide()
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity


func handle_interaction():
	var interactable = interact.get_overlapping_areas()
	if verify_patern("..-") and interactable.size() > 0 and list_time.size() > 3:
		if interactable[0].is_in_group("oppenable"):
			interactable[0].get_parent().hide()
			list_time = []
		elif interactable[0].is_in_group("interactable"):
			interactable[0].get_parent().activate()
			list_time = []
