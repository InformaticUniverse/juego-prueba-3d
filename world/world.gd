extends Node3D

@onready var game_over_scene = preload("res://menus/GameOver.tscn")
var game_over_instance: Control = null
var is_game_over: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Connect to all enemies' player_hit signals
	_connect_enemies()

func _connect_enemies() -> void:
	# Find all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		# If no enemies in group, find them by script
		for child in get_children():
			if child.has_method("_on_follow_target_3d_navigation_finished"):
				# This is likely an enemy
				if child.has_signal("player_hit"):
					child.player_hit.connect(_on_player_hit)
	else:
		for enemy in enemies:
			if enemy.has_signal("player_hit"):
				enemy.player_hit.connect(_on_player_hit)
	
	# Also check for ExampleEnemy node specifically
	var example_enemy = get_node_or_null("ExampleEnemy")
	if example_enemy and example_enemy.has_signal("player_hit"):
		example_enemy.player_hit.connect(_on_player_hit)

func _on_player_hit() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	show_game_over()

func show_game_over() -> void:
	# Pause the game
	get_tree().paused = true
	
	# Create and show game over menu
	game_over_instance = game_over_scene.instantiate()
	add_child(game_over_instance)
	
	# Connect button signals
	var restart_button = game_over_instance.get_node_or_null("CenterContainer/VBoxContainer/ButtonContainer/RestartButton")
	var quit_button = game_over_instance.get_node_or_null("CenterContainer/VBoxContainer/ButtonContainer/QuitButton")
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Show mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed() -> void:
	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	# Quit the game
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
