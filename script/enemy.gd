# ProtoController v1.0 by Brackeys
# Edited by Treidex

class_name Enemy
extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = true

@export_group("Speeds")
## Normal speed.
@export var base_speed : float = 5.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0

var is_sprinting: bool
var move_speed : float = 0.0

## IMPORTANT REFERENCES
@onready var collider: CollisionShape3D = $Collider
@onready var model: Node3D = $characterMedium
@onready var animation: AnimationPlayer = $characterMedium/AnimationPlayer
		
func try_jump() -> void:
	if can_jump and is_on_floor():
		velocity.y = jump_velocity
		
func try_move(input_dir: Vector2, try_sprint: bool) -> void:
	is_sprinting = try_sprint;
	if is_sprinting:
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)
	if can_move:
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	
func _physics_process(delta: float) -> void:
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta
			animation.play("jump/Root|Jump");
			move_and_slide();
			return;
	
	if GameContext.instance.player:
		var want_pos = GameContext.instance.player.global_position;
		look_at(want_pos);
		rotation.x = clamp(rotation.x, deg_to_rad(-20), deg_to_rad(20))
		try_move(Vector2(0, -1), true);
	
	if not is_on_floor():
		animation.play("jump/Root|Jump");
	elif velocity.x or velocity.y:
		var wasnt_playing = animation.current_animation != "run/Root|Run"; # whats bad code?
		animation.play("run/Root|Run", -1, lerp(0.5, 1.0, is_sprinting));
		if wasnt_playing:
			animation.seek((randi() % 2) * animation.current_animation_length / 2, true);
	else:
		animation.play("idle/Root|Idle");
	
	# Use velocity to actually move
	move_and_slide()
	
