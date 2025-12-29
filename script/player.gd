# ProtoController v1.0 by Brackeys
# Edited by Treidex

class_name Player
extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = true
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.005
## Normal speed.
@export var base_speed : float = 5.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var animation: AnimationPlayer = $characterMedium/AnimationPlayer

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
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed("freefly"):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta
			animation.play("jump/Root|Jump");
			move_and_slide();
			return;

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	var sprinting: bool;
	if can_sprint and Input.is_action_pressed("sprint"):
		move_speed = sprint_speed
		sprinting = true;
	else:
		move_speed = base_speed
		sprinting = false;

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	if not is_on_floor():
		animation.play("jump/Root|Jump");
	elif velocity.x or velocity.y:
		var wasnt_playing = animation.current_animation != "run/Root|Run"; # whats bad code?
		animation.play("run/Root|Run", -1, lerp(0.5, 1.0, sprinting));
		if wasnt_playing:
			animation.seek((randi() % 2) * animation.current_animation_length / 2, true);
	else:
		animation.play("idle/Root|Idle");
	
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-40), deg_to_rad(65))
	look_rotation.y -= rot_input.x * look_speed
	#transform.basis = Basis()
	if is_on_floor():
		global_rotation.y = look_rotation.y;
	#head.transform.basis = Basis()
	head.global_rotation.x = look_rotation.x;
	head.global_rotation.y = look_rotation.y;

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _on_enemy_detected(body: Node3D) -> void:
	print(body);
	if body is Enemy:
		tackle(body);

func tackle(body: Enemy) -> void:
	body.can_move = false;
	body.can_jump = false;
	body.has_gravity = false;
	
	
