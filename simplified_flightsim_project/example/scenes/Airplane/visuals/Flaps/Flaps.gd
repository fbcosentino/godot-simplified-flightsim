extends Node3D

# Any node can receive the "update_interface" signals from the Airplane modules
# This can be used to show realtime representations using the same data
# as the UI controls

var target_flap_position = 0.0


func _on_Flaps_update_interface(values):
	target_flap_position = deg_to_rad(values["flap"]*45.0)


func _process(delta):
	$FlapRotation.rotation.x = lerp($FlapRotation.rotation.x, target_flap_position, delta*5.0)

