class_name GameContext
extends Node

static var instance: GameContext = null;

@export var player: Player;

func _ready() -> void:
	assert(instance == null);
	instance = self;

func free() -> void:
	assert(instance == self);
	instance = null;
