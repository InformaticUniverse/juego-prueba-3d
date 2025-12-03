extends CharacterBody3D

signal player_hit

enum States {
	Walking,
	Pursuit
}

@export var walkSpeed : float = 2.0
@export var runSpeed : float = 5.0

@onready var follow_target_3d: FollowTarget3D = $FollowTarget3D
@onready var random_target_3d: RandomTarget3D = $RandomTarget3D
@onready var geometry_mesh: MeshInstance3D = $Geometry
@onready var cylinder_mesh: MeshInstance3D = $Geometry/MeshInstance3D

var state : States = States.Walking
var target : Node3D
var has_hit_player: bool = false

func _ready() -> void:
	# Create unique material instances for this enemy to avoid sharing with others
	_create_unique_materials()
	ChangeState(States.Walking)
	_set_color(Color(0, 1, 0, 1))  # Start green

func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func ChangeState(newState : States) -> void:
	state = newState
	match state:
		States.Walking:
			follow_target_3d.ClearTarget()
			follow_target_3d.Speed = walkSpeed
			follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())
			target = null
			_set_color(Color(0, 1, 0, 1))  # Green when not following
		States.Pursuit:
			follow_target_3d.Speed = runSpeed
			follow_target_3d.SetTarget(target)
			_set_color(Color(1, 0, 0, 1))  # Red when following

func _on_follow_target_3d_navigation_finished() -> void:
	follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())

func _on_simple_vision_3d_get_sight(body: Node3D) -> void:
	target = body
	ChangeState(States.Pursuit)

func _on_simple_vision_3d_lost_sight() -> void:
	ChangeState(States.Walking)

func _on_follow_target_3d_reached_target(target_node: Node3D) -> void:
	# Check if the target is the player and we haven't already hit them
	if target_node and target_node.is_in_group("player") and not has_hit_player:
		# Check if player is stomping (above enemy)
		if _is_player_stomping(target_node):
			die()
		else:
			has_hit_player = true
			player_hit.emit()

func _on_hit_area_body_entered(body: Node3D) -> void:
	# Check if the body is the player and we haven't already hit them
	if body and body.is_in_group("player") and not has_hit_player:
		# Check if player is stomping (above enemy and falling)
		if _is_player_stomping(body):
			die()
		else:
			has_hit_player = true
			player_hit.emit()

## Checks if the player is stomping the enemy (Mario-style)
func _is_player_stomping(player: Node3D) -> bool:
	if not player:
		return false
	
	# Check if player is above the enemy
	var height_difference = player.global_position.y - global_position.y
	var is_above = height_difference > 0.5  # Player must be at least 0.5 units above
	
	# Check if player is falling (has downward velocity)
	var player_velocity = Vector3.ZERO
	if player is CharacterBody3D:
		player_velocity = (player as CharacterBody3D).velocity
	var is_falling = player_velocity.y <= 0
	
	return is_above and is_falling

## Called when the enemy is stomped by the player (Mario-style).
func die() -> void:
	# Prevent multiple death triggers
	if has_hit_player:
		return
	
	has_hit_player = true
	
	# Disable all enemy behaviors
	if follow_target_3d:
		follow_target_3d.ClearTarget()
	
	# Remove collision so player can pass through
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		collision.set_deferred("disabled", true)
	
	# Disable hit area
	var hit_area = get_node_or_null("HitArea")
	if hit_area:
		hit_area.set_deferred("monitoring", false)
		hit_area.set_deferred("monitorable", false)
	
	# Make enemy invisible or play death animation
	var geometry = get_node_or_null("Geometry")
	if geometry:
		geometry.visible = false
	
	# Give player a small bounce boost
	var player = get_tree().get_first_node_in_group("player")
	if player and player is CharacterBody3D:
		(player as CharacterBody3D).velocity.y = 3.0  # Small bounce
	
	# Queue for deletion after a short delay
	await get_tree().create_timer(0.1).timeout
	queue_free()

## Creates unique material instances for this enemy to avoid sharing with others
func _create_unique_materials() -> void:
	if geometry_mesh:
		var material = geometry_mesh.get_surface_override_material(0)
		if material:
			# Duplicate to create a unique instance for this enemy
			geometry_mesh.set_surface_override_material(0, material.duplicate())
		else:
			# Create a new material if none exists
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = Color(0, 1, 0, 1)  # Start green
			geometry_mesh.set_surface_override_material(0, new_material)
	
	if cylinder_mesh:
		var material = cylinder_mesh.get_surface_override_material(0)
		if material:
			# Duplicate to create a unique instance for this enemy
			cylinder_mesh.set_surface_override_material(0, material.duplicate())
		else:
			# Create a new material if none exists
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = Color(0, 1, 0, 1)  # Start green
			cylinder_mesh.set_surface_override_material(0, new_material)

## Changes the color of the enemy mesh materials
func _set_color(color: Color) -> void:
	if geometry_mesh:
		var material = geometry_mesh.get_surface_override_material(0)
		if material:
			material.albedo_color = color
		else:
			# Create a new material if none exists
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = color
			geometry_mesh.set_surface_override_material(0, new_material)
	
	if cylinder_mesh:
		var material = cylinder_mesh.get_surface_override_material(0)
		if material:
			material.albedo_color = color
		else:
			# Create a new material if none exists
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = color
			cylinder_mesh.set_surface_override_material(0, new_material)
