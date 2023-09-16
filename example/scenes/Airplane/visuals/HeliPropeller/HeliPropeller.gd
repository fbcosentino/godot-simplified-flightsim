extends Node3D



# Any node can receive the "update_interface" signals from the Airplane modules
# This can be used to show realtime representations using the same data
# as the UI controls


@onready var blades = $Blades

@export var AccelSpeed: float = 0.5
@export var MaxRotationSpeed: float = 100.0

var mat
var rotation_speed = 0.0
var target_rotation_speed = 0.0
var is_changing_speed = false

func _ready():
	# Material must be made unique in order to have independent mesh copies
	mat = $Disc.get_surface_override_material(0).duplicate()
	$Disc.set_surface_override_material(0, mat)

func _on_Engine_update_interface(values):
	target_rotation_speed = 0.0 if not values["engine_active"] else 0.2 + values["engine_power"]*0.8
	is_changing_speed = true

func _physics_process(delta):
	if is_changing_speed:
		var frame_move_delta = AccelSpeed * delta
		# Close enough to complete it?
		if abs(target_rotation_speed - rotation_speed) <= frame_move_delta:
			# Just complete it
			rotation_speed = target_rotation_speed
			is_changing_speed = false
		else:
			# Still some way to go
			rotation_speed += (frame_move_delta) if target_rotation_speed > rotation_speed else (-frame_move_delta)
		
		mat.albedo_color.a = clamp(rotation_speed, 0.0, 0.5)
	
	if rotation_speed > 0:
		blades.rotation.y -= MaxRotationSpeed * rotation_speed * delta
