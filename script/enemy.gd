# ProtoController v1.0 by Brackeys
# Edited by Treidex

class_name Enemy
extends CharacterBody3D

## Look around rotation speed.
@export var look_speed : float = 0.005
## Normal speed.
@export var base_speed : float = 5.0
## Speed of jump.
@export var jump_velocity : float = 5
## How fast do we run?
@export var sprint_speed : float = 10.0

@export var want_pos : Vector3

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float :
	get:
		if is_sprinting:
			return sprint_speed;
		else:
			return base_speed;
var is_sprinting : bool = false
var is_freeflying : bool = false

var move_input : Vector2 = Vector2.ZERO;

## IMPORTANT REFERENCES
@onready var collider: CollisionShape3D = $Collider
#@onready var animation: AnimationPlayer = $characterMedium/AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree;
@onready var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback");

func _ready() -> void:
	look_rotation.y = rotation.y
	#look_rotation.x = head.rotation.x
	
func _physics_process(delta: float) -> void:
	var want_playback := "Idle";
	
	#if GameContext.instance.player:
		#var want_pos = GameContext.instance.player.global_position;
	var d = want_pos - global_position;
	look_rotation.x = atan2(d.y, Vector2(d.x, d.z).length());
	look_rotation.y = atan2(-d.x, -d.z);
	move_input = Vector2(0, -1);
	
	# Apply gravity to velocity
	if not is_on_floor():
		velocity += get_gravity() * delta
		want_playback = "Air";
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if can_move():
			is_sprinting = Input.is_action_pressed("sprint");
			var move_dir = (transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()
			anim_tree.set("parameters/Walk/blend_position", move_input);
			anim_tree.set("parameters/Run/blend_position", move_input);
			if move_dir:
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
				if is_sprinting:
					want_playback = "Run";
				else:
					want_playback = "Walk";
	
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
	#head.global_rotation.x = look_rotation.x;
	#head.global_rotation.y = look_rotation.y;

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
		body.can_move = false;
