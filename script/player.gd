# ProtoController v1.0 by Brackeys
# Edited by Treidex

class_name Player
extends CharacterBody3D

## Look around rotation speed.
@export var look_speed : float = 0.005
## Normal speed.
@export var base_speed : float = 5.0
## Speed of jump.
@export var jump_velocity : float = 5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float :
	get:
		if is_freeflying:
			return freefly_speed;
		elif is_sprinting:
			return sprint_speed;
		else:
			return base_speed;
var is_sprinting : bool = false
var is_freeflying : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
#@onready var animation: AnimationPlayer = $characterMedium/AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree;
@onready var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback");

func _ready() -> void:
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		var rot_input = event.relative;
		look_rotation.x -= rot_input.y * look_speed
		look_rotation.y -= rot_input.x * look_speed
	
	# Toggle freefly mode
	if Input.is_action_just_pressed("freefly"):
		if not is_freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if is_freeflying:
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		rotate_look();
		return;
	
	var want_playback := "Idle";
	
	# Apply gravity to velocity
	if not is_on_floor():
		velocity += get_gravity() * delta
		want_playback = "Air";
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		var move_dir := Vector3.ZERO;
		if can_move():
			is_sprinting = Input.is_action_pressed("sprint");
			var input = Input.get_vector("left", "right", "forward", "backward");
			move_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
			anim_tree.set("parameters/Walk/blend_position", input);
			anim_tree.set("parameters/Run/blend_position", input);
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			if is_sprinting:
				want_playback = "Run";
			else:
				want_playback = "Walk";
		
		if Input.is_action_just_pressed("jump"):
			if playback.get_current_node() == "Run" and not playback.get_fading_from_node():
				velocity.y = jump_velocity
			else:
				want_playback = "Jump";
	
	if Input.is_action_just_pressed("lift"):
		want_playback = "DeadLift";
	
	if Input.is_action_just_pressed("dance"):
		want_playback = "Dance";
	
	# Use velocity to actually move
	playback.travel(want_playback);
	move_and_slide();
	rotate_look();


func can_move() -> bool:
	return is_on_floor() and ["Idle", "Walk", "Run"].has(playback.get_current_node());

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look():
	#transform.basis = Basis()
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-40), deg_to_rad(65))
	if can_move():
		global_rotation.y = look_rotation.y;
	#head.transform.basis = Basis()
	head.global_rotation.x = look_rotation.x;
	head.global_rotation.y = look_rotation.y;

func enable_freefly():
	collider.disabled = true
	is_freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	is_freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _on_enemy_detected(body: Node3D) -> void:
	print(body);
	#if body is Enemy:
		#tackle(body);

func tackle(body: Enemy) -> void:
	pass
	
func _on_clumsy_body_entered(body: Node3D) -> void:
	if not is_sprinting:
		return;
	
	var air_bonus = 1;
	if not is_on_floor():
		air_bonus = 1.5;
	
	var d = body.global_position - global_position;
	d.y = 0;
	d = d.normalized();
	if body is RigidBody3D:
		body.apply_impulse((d * 5 + Vector3.UP * 0.5) * air_bonus);
	if body is Enemy:
		body.velocity += (d.normalized() * 15 + Vector3.UP * 5) * air_bonus;
