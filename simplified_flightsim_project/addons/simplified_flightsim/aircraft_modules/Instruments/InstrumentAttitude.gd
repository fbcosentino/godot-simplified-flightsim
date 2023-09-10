extends AircraftModule
class_name AircraftModule_InstrumentAttitude

signal update_interface(values)



# You don't really *need* to use this property, as any node can receive the
# signals. This is just a helper to automatically connect all possible signals
# assigning the node just once 
@export var UINode: NodePath
@onready var ui_node = get_node_or_null(UINode)

var current_roll = 0.0
var current_pitch = 0.0
var current_bearing = 0.0
var current_altitude = 0.0
var current_latitude = 0.0
var current_longitude = 0.0

func _ready():
	if ui_node:
		connect("update_interface", Callable(ui_node, "update_interface"))
	
	ProcessPhysics = true

func setup(aircraft_node):
	aircraft = aircraft_node
	request_update_interface()

func request_update_interface():
	var message = {
		"roll": rad_to_deg(current_roll),
		"pitch": rad_to_deg(current_pitch),
		"bearing": rad_to_deg(current_bearing),
		"alt": aircraft.local_altitude,
		"speed": aircraft.air_velocity,
		"g": aircraft.local_g_force,
		"load_factor": aircraft.local_load_factor,
	}
	emit_signal("update_interface", message)

func process_physic_frame(delta):
	if (not aircraft) or (not aircraft.world_ref):
		return
	
	var local_countergravity = Vector3.ZERO
	var local_north = Vector3.ZERO
	

	
	local_countergravity = -aircraft.local_gravity_direction
	
	match aircraft.WorldType:
		aircraft.WorldTypes.LINEAR:
			local_north = aircraft.to_local(aircraft.global_transform.origin - aircraft.world_ref.global_transform.basis.z).normalized()
			
			current_latitude = -aircraft.location_in_world_frame.z
			current_longitude = aircraft.location_in_world_frame.x
			
		aircraft.WorldTypes.SPHERICAL:
			#local_countergravity = -aircraft.to_local(aircraft.world_ref.global_transform.origin).normalized()
			#local_north = aircraft.to_local(aircraft.global_transform.origin + world_ref.global_transform.basis.y).normalized()
			
			current_latitude = asin(aircraft.direction_in_world_frame.y)
			current_longitude = atan2(aircraft.direction_in_world_frame.x, aircraft.direction_in_world_frame.z)
			# Magnetic vector is a composition of world's basis.y and the equator projection to center
			var equator_proj_center = aircraft.world_ref.to_global(Vector3(
					-aircraft.direction_in_world_frame.x, 
					0.0, 
					-aircraft.direction_in_world_frame.z)
				) - aircraft.world_ref.global_transform.origin
			var lat_normalized = current_latitude/(0.5*PI) # lat_normalized range: [-1, +1] (pole-to-pole)
			# Around the equator (lat_normalized around zero), magnetic vector is mostly basis.y
			# Around the poles (lat_normalized around +-1), magnetic vector is mostly center projection
			# South hemisphere it points out, nothern points in
			var mag_vec_factor = abs(lat_normalized)
			var mag_vector = lerp( # in global frame but zero origin
				aircraft.world_ref.global_transform.basis.y,
				equator_proj_center * sign(lat_normalized),
				mag_vec_factor
			)
			local_north = aircraft.to_local(aircraft.global_transform.origin + mag_vector)
			
	current_roll = atan2(-local_countergravity.x, local_countergravity.y)
	current_pitch = atan2(-local_countergravity.z,
		Vector2(local_countergravity.x, local_countergravity.y).length() # Projection on XY
	)
	var compensated_north = local_north.rotated(Vector3.FORWARD, current_roll)
	current_bearing = atan2(-compensated_north.x, -compensated_north.z)
	if current_bearing < 0:
		current_bearing += TAU
	
	request_update_interface()

# Currently not used, but available
func tilt_compensated_bearing(mx: float, my: float, mz: float, r: float, p: float) -> float:
	# From: https://www.best-microcontroller-projects.com/magnetometer-tilt-compensation.html
	
	# Buffer vars to avoid calling trigonometric functions more than once
	var cos_r = cos(r)
	var sin_r = sin(r)
	var cos_p = cos(p)
	var sin_p = sin(p)
	
	var compensated_x = mx*cos_p + my*sin_r*sin_p - mz*cos_r*sin_p
	var compensated_y = my*cos_r + mz*sin_r
	
	return atan2(compensated_y, compensated_x)
