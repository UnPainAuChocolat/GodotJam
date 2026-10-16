extends Sprite3D

@export var min_bounds: Vector2 = Vector2(-50, -50)
@export var max_bounds: Vector2 = Vector2(50, 50)
@export var search_speed: float = 10.0
@export var spotlight_radius: float = 4.0 # How wide the light beam's detection zone is on the ground

@onready var raycast: RayCast3D = $Pivot/RayCast3D
@onready var spotlight: SpotLight3D = $Pivot/SpotLight3D
@onready var beam_pivot = self

var current_target_pos: Vector3
var next_destination: Vector3
var on_player: bool = false
var tracked_player

func _ready() -> void:
	raycast.enabled = true
	raycast.target_position = Vector3(0, -500, 0)
	
	current_target_pos = _get_random_ground_pos()
	next_destination = _get_random_ground_pos()

func _get_random_ground_pos() -> Vector3:
	return Vector3(
		global_position.x + randf_range(min_bounds.x, max_bounds.x),
		0.0,
		global_position.z + randf_range(min_bounds.y, max_bounds.y)
	)

func _physics_process(delta: float) -> void:
	raycast.force_raycast_update()
	
	var player = get_tree().get_first_node_in_group("Player")
	var player_detected = false
	
	if player and is_instance_valid(player):
		var target_pos_2d = Vector2(current_target_pos.x, current_target_pos.z)
		var player_pos_2d = Vector2(player.global_position.x, player.global_position.z)
		var distance = target_pos_2d.distance_to(player_pos_2d)
		
		if distance <= spotlight_radius:
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(beam_pivot.global_position, player.global_position)
			query.exclude = [self]
			
			var result = space_state.intersect_ray(query)
			
			if result and result.collider == player:
				player_detected = true

	if player_detected:
		on_player = true
		tracked_player = player
		player.under_eye = true
		player.health += 0.3 * delta
	else:
		if on_player:
			if is_instance_valid(tracked_player):
				tracked_player.under_eye = false
			tracked_player = null
			on_player = false
			next_destination = _get_random_ground_pos()

	if on_player and is_instance_valid(tracked_player):
		next_destination = tracked_player.global_position
	elif current_target_pos.distance_to(next_destination) < 1.0 and not on_player:
		next_destination = _get_random_ground_pos()
		
	current_target_pos = current_target_pos.move_toward(next_destination, search_speed * delta)
	
	if beam_pivot.global_position.distance_to(current_target_pos) > 0.1:
		beam_pivot.look_at(current_target_pos, Vector3.UP)
