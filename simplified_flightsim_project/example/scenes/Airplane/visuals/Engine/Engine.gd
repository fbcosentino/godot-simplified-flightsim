extends Spatial



# Any node can receive the "update_interface" signals from the Airplane modules
# This can be used to show realtime representations using the same data
# as the UI controls

var mat

func _ready():
	# Material must be made unique in order to have independent mesh copies
	mat = $MeshInstance.get_surface_material(0).duplicate()
	$MeshInstance.set_surface_material(0, mat)

func _on_Engine_update_interface(values):
	var power = values["engine_power"]
	scale.z = 0.05+power
	mat.albedo_color = lerp(Color.black, Color.white, power)
