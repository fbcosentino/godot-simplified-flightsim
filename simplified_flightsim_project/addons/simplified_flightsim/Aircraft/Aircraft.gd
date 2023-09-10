@icon("res://addons/simplified_flightsim/Aircraft/Aircraft_icon.png")
class_name Aircraft
extends RigidBody3D

signal crashed(impact_velocity)
signal parked
signal moved
signal stall_changed(state)
signal atmospheric_calculations_requested

const AIR_DENSITY_RHO = 1.225
const SPECIFIC_HEAT_CAPACITY_AIR = 0.718
const ZERO_C_IN_K = 273.15
const STEFAN_BOLTZMANN = 5.670374419 * 0.00000001 # σ = 5.670374419... × 10^−8 [W⋅m^−2⋅K^−4]
const RATIO_OF_SPECIFIC_HEATS = 1.4 # for dry air at 300K
const SPEED_OF_SOUND = 343.0 # mach 1
const EARTH_GRAVITY = 9.8 # for g-force calculation

# Lift factor combines lift coefficient and wing area
# Must be higher than DragFactor.z or the plane won't take off
@export var LiftFactor: float = 0.03
@export var LiftPointDistance: float = 0.0 # meters ahead of center of mass

# Drag factor combines drag coefficient and reference area
@export var DragFactor: Vector3 = Vector3(1, 2, 0.02)
@export var DragPointDistance: float = 1.0 # meters behind center of mass

@export var DragHeatRate: float = 0.1
@export var RadiationCoolingRate: float = 1.0

@export var MachSpeedScaling: float = 1.0
@export var GForceFactor: float = 1.0 # Used by both G-Force and Load Factor

@export var MaxTemperature: float = 900.0 # Celsius
@export var EnableTemperatureCalculations: bool = false

@export var AirDensity: float = 1.0
@export var AirTemperature: float = 25.0: set = set_temperature
@onready var air_temperature_K = ZERO_C_IN_K + AirTemperature

@export var MaxLandingForce: float = 1.0

@export var Gravity: float = 1.0 # Normalized to Earth average at sea level
@export var SeaLevelFromOrigin: float = 0.0
@export var AltitudeEnabled: bool = true

# Linear world is Godot default: reference Y axis is always UP, reference -Z axis is always NORTH
# Spherical world is real life: away from reference origin is UP, reference Y axis is magnetic NORTH
enum WorldTypes {
	LINEAR,
	SPHERICAL
}
@export var WorldType: WorldTypes = WorldTypes.LINEAR

# A Spatial-derived node used as reference for UP and NORTH
# If not provided, the global origin and axes are used
@export var WorldOrientationReference: NodePath
@onready var world_ref : Node3D = get_node_or_null(WorldOrientationReference)
var internal_world_reference : Node3D

var last_global_position = null
var last_linear_velocity = null
var last_angular_velocity = null

var air_velocity_vector = Vector3.ZERO
var air_velocity = 0.0
var air_velocity_squared = 0.0
var mach_speed = 0.0
var forward_air_speed = 0.0
var lift_intensity = 0.0
var drag_intensity_vector = Vector3.ZERO
var local_gravity_direction = Vector3.DOWN
var local_altitude = 0.0
var location_in_world_frame = Vector3.ZERO
var direction_in_world_frame = Vector3.ZERO
var stagnation_temperature_K = 0.0
var local_temperature = AirTemperature # Celsius
var local_load_factor = 1.0
var local_g_force = 1.0

var touching_shapes = []
var is_safe_touching = false
var is_unsafe_touching = false
var is_velocity_nonzero = false
var is_stalled = false

##############################################################################
#  SYSTEM SETUP
# ----------------------------------------------------------------------------

var modules = []
var energy_containers = []
var energy_containers_by_type = {}
var available_energy = {
	"fuel": 0.0
}
var energy_budget_frame = {}
var safe_colliders = []

func _ready():
	await get_tree().process_frame 
	internal_world_reference = get_node_or_null("/root/WorldOrientationReference") # avoids creating more than one
	if not internal_world_reference:
		internal_world_reference = Node3D.new()
		internal_world_reference.name = "WorldOrientationReference"
		get_node("/root/").add_child(internal_world_reference)
	if not world_ref:
		world_ref = internal_world_reference
	
	connect("body_shape_entered", Callable(self, "_on_Aircraft_body_shape_entered"))
	connect("body_shape_exited", Callable(self, "_on_Aircraft_body_shape_exited"))
	
	for child in get_children():
		if (child is AircraftModule) or (child is AircraftModuleSpatial):
			modules.append(child)
			
			if child is AircraftModule_EnergyContainer:
				energy_containers.append(child)
				
				if not child.EnergyType in energy_containers_by_type:
					energy_containers_by_type[child.EnergyType] = []
				energy_containers_by_type[child.EnergyType].append(child)
				
				if not child.EnergyType in available_energy:
					available_energy[child.EnergyType] = 0.0
	
	gravity_scale = 0.0 # Disable Godot's internal gravity calculation
	
	# We need to make sure the modules Array is fully populated before calling
	# setup() (that's why setup() exists, instead of just using _ready())
	setup()

func setup():
	for module in modules:
		module.setup(self)

func _unhandled_input(event):
	for module in modules:
		if module.ReceiveInput:
			module.receive_input(event)

func _physics_process(delta):
	if not world_ref:
		return
	
	
	prepare_physics_variables()
	
	
	# All state variables should be calculated prior to calling modules,
	# so they are available to them
	
	for module in modules:
		if module.ProcessPhysics:
			module.process_physic_frame(delta)
	
	# Applying forces goes after modules, so they can be modified by them
	process_physics_frame(delta)

func _process(delta):
	if not world_ref:
		return
	
	for module in modules:
		if module.ProcessRender:
			module.process_render_frame(delta)


func _on_Aircraft_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	update_collision_flags()
	
	var collider_shape = shape_owner_get_owner(local_shape_index)
	
	var impact_force = linear_velocity.length()
	
	if collider_shape in safe_colliders:
		var landing_force = linear_velocity.dot(global_transform.basis.y)
		land(landing_force, impact_force)
	else:
		crash(impact_force)
	

func _on_Aircraft_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	update_collision_flags()
	

func update_collision_flags():
	var my_state = PhysicsServer3D.body_get_direct_state(get_rid())
	if (not my_state):
		return
	
	var contact_count = my_state.get_contact_count()
	
	var safe_found = false
	var unsafe_found = false
	
	for i in range(contact_count):
		var collider_shape = shape_owner_get_owner(my_state.get_contact_local_shape(i))
		if collider_shape in safe_colliders:
			safe_found = true
		else:
			unsafe_found = true
			
	is_safe_touching = safe_found
	is_unsafe_touching = unsafe_found

func set_temperature(value: float):
	AirTemperature = value
	air_temperature_K = ZERO_C_IN_K + value

##############################################################################
#  UTILITY FUNCTIONS
# ----------------------------------------------------------------------------

func find_modules_by_type(module_type: String) -> Array:
	var result = []
	for module in modules:
		if module.ModuleType == module_type:
			result.append(module)
	return result

func find_modules_by_tag(module_tag: String) -> Array:
	var result = []
	for module in modules:
		if module_tag in module.ModuleTags:
			result.append(module)
	return result

func find_modules_by_type_and_tag(module_type: String, module_tag: String) -> Array:
	var result = []
	for module in modules:
		if (module.ModuleType == module_type) and (module_tag in module.ModuleTags):
			result.append(module)
	return result

func register_safe_collider(collider: CollisionShape3D):
	if not collider in safe_colliders:
		safe_colliders.append(collider)

func unregister_safe_collider(collider: CollisionShape3D):
	if collider in safe_colliders:
		safe_colliders.erase(collider)


##############################################################################
#  SIMULATION FUNCTIONS
# ----------------------------------------------------------------------------

func prepare_physics_variables():
	# This method is called in physics process, before modules
	
	if last_global_position == null:
		last_global_position = global_transform.origin
	var delta_position = global_transform.origin - last_global_position
	
	air_velocity_vector = to_local(global_transform.origin + linear_velocity)
	air_velocity_squared = air_velocity_vector.length_squared()
	air_velocity = air_velocity_vector.length()
	
	forward_air_speed = -air_velocity_vector.z
	#forward_air_speed = linear_velocity.dot(-global_transform.basis.z)
	var forward_air_speed_squared = forward_air_speed*forward_air_speed
	
	
	location_in_world_frame = world_ref.to_local(global_transform.origin)
	direction_in_world_frame = location_in_world_frame.normalized()
	
	match WorldType:
		WorldTypes.LINEAR:
			local_gravity_direction = to_local(global_transform.origin - world_ref.global_transform.basis.y).normalized()
			if AltitudeEnabled:
				local_altitude = location_in_world_frame.y - SeaLevelFromOrigin
			else:
				local_altitude = 0.0
		
		WorldTypes.SPHERICAL:
			local_gravity_direction = to_local(world_ref.global_transform.origin).normalized()
			if AltitudeEnabled:
				local_altitude = location_in_world_frame.length() - SeaLevelFromOrigin
			else:
				local_altitude = 0.0
	
	mach_speed = (air_velocity*MachSpeedScaling) / SPEED_OF_SOUND
	
	if EnableTemperatureCalculations:
		stagnation_temperature_K = air_temperature_K * (1.0 + (RATIO_OF_SPECIFIC_HEATS - 1.0)*0.5*(mach_speed*mach_speed))
	
	var energy_levels = {}
	for energy_cont in energy_containers:
		if energy_cont.ContainerActive:
			if not energy_cont.EnergyType in energy_levels:
				energy_levels[energy_cont.EnergyType] = energy_cont.current_level
			else:
				energy_levels[energy_cont.EnergyType] += energy_cont.current_level
	available_energy = energy_levels
	for energy_type in available_energy:
		energy_budget_frame[energy_type] = 0.0
	
	
	# Any external nodes should use this callback to make sure variables are updated at the right time
	emit_signal("atmospheric_calculations_requested")	
	
	
	# Lift equation: https://www.grc.nasa.gov/www/k-12/airplane/lifteq.html
	lift_intensity = LiftFactor * AirDensity * (AIR_DENSITY_RHO * forward_air_speed_squared)/2 # (rho * V^2)/2
	
	# Drag equation: https://www.grc.nasa.gov/www/k-12/airplane/drageq.html
	drag_intensity_vector = Vector3(
		sign(-air_velocity_vector.x) * DragFactor.x * (AIR_DENSITY_RHO * air_velocity_vector.x*air_velocity_vector.x)/2,
		sign(-air_velocity_vector.y) * DragFactor.y * (AIR_DENSITY_RHO * air_velocity_vector.y*air_velocity_vector.y)/2,
		sign(-air_velocity_vector.z) * DragFactor.z * (AIR_DENSITY_RHO * air_velocity_vector.z*air_velocity_vector.z)/2
	) * AirDensity



var _process_frame_count = 0
func process_physics_frame(delta):
	# This method is called in physics process, after modules
	# Process passive forces (lift, drag, heat, collision)
	
	var up_vector = global_transform.basis.y # roof of plane on global frame
	var forward_vector = -global_transform.basis.z # nose of plane in global frame
	var right_vector = global_transform.basis.x # right wing of plane in global frame
	
	# Both are in global coordinates
	var linear_acceleration = (linear_velocity - last_linear_velocity) / delta if last_linear_velocity != null else Vector3.ZERO
	var angular_acceleration = (angular_velocity - last_angular_velocity) / delta if last_angular_velocity != null else Vector3.ZERO
	
	# ================
	# LIFT
	
	var lift_vector = up_vector * lift_intensity
	apply_force(lift_vector, forward_vector * LiftPointDistance)
	
	
	# ================
	# DRAG
	
	# Add drag
	# Convert drag from local rotation to global rotation
	var drag_vec_global_rotation = to_global(drag_intensity_vector) - global_transform.origin
	# Apply drag
	apply_force(drag_vec_global_rotation, -forward_vector * DragPointDistance)
	
	angular_damp = 1.0 + ((drag_intensity_vector.length_squared())*0.01)*AirDensity
	
	# ================
	# HEAT
	
	if EnableTemperatureCalculations:
		var local_temperature_K = (ZERO_C_IN_K + local_temperature)
		
		# https://en.wikipedia.org/wiki/Nusselt_number -> average number for forced laminar flow: 0.664
		var heat_velocity_factor = air_velocity*0.664 
		# DragHeatRate combines friction coefficient (ext dT -> heat) and specific capacity (heat -> int dT)
		# therefore the equation input and output is both temperature (per unit of time)
		var delta_to_stagnation = (stagnation_temperature_K - local_temperature_K)
		var temperature_intake = min(DragHeatRate * heat_velocity_factor * delta_to_stagnation * delta, delta_to_stagnation) # min() avoids going beyond stagnation
		# temperature_intake can be negative, when cooling down
		
		# Heat loss due to radiation as black body - all temperature radiates but only delta is used since
		# the air radiates heat back to us as well
		var body_delta_temp = local_temperature_K - air_temperature_K
		var local_temperature_K4 = body_delta_temp*body_delta_temp*body_delta_temp*body_delta_temp
		# RadiationCoolingRate combines ratiated heat (dT -> heat) and heat capacity (heat -> dT)
		# therefore the equation input and output is both temperature (per unit of time)
		var radiated_temperature_outtake = RadiationCoolingRate * STEFAN_BOLTZMANN * local_temperature_K4 * delta
		
		# Finally apply temperature changes
		local_temperature = max(local_temperature + (temperature_intake - radiated_temperature_outtake), -ZERO_C_IN_K) # max() avoids going below 0K
		
		if local_temperature > MaxTemperature:
			call_deferred("emit_signal", "crashed", -1)
		
	#	if (_process_frame_count % 10) == 0: # once every 10 frames
	#		print("Convec: %.03f     Rad: %.03f      Final: %.03f                                %.03f" % [
	#				temperature_intake, radiated_temperature_outtake, local_temperature,
	#				stagnation_temperature_K - ZERO_C_IN_K])
		
	# ================
	# GRAVITY
	
	var weight_vector = Vector3.ZERO
	if Gravity > 0:
		var global_gravity_direction = to_global(local_gravity_direction) - global_transform.origin
		weight_vector = global_gravity_direction * EARTH_GRAVITY * Gravity
		apply_central_force(weight_vector)
	
	# Load Factor and G-Force
	# load factor is based on the planet's gravity, so level flight always have load factor of 1.0
	# g is always based on Earth gravity, so a planet where gravity factor is 0.5 would have a 
	# level flight g force of 0.5 instead of 1
	
	var vertical_acceleration_normalized = (up_vector.dot(linear_acceleration) / EARTH_GRAVITY) * GForceFactor # Positive means to the aircraft roof
	
	local_load_factor = (1.0 + vertical_acceleration_normalized/Gravity) if Gravity > 0 else 0.0
	local_g_force = (Gravity + vertical_acceleration_normalized) if Gravity > 0 else 0.0
	
	# ================
	# STALL
	
	var lift_weight_balance = (lift_vector.length_squared() - weight_vector.length_squared())
	var is_stall_now = lift_weight_balance < 0
	if is_stalled != is_stall_now:
		is_stalled = is_stall_now
		emit_signal("stall_changed", is_stalled)
	
	
	# ================
	# ENERGY
	
	consume_energy_budget()
	
	
	# ================
	# PHYSICAL COLLAPSE AND STATE SIGNALS
	
	var is_moving_now = (air_velocity > 0.005)
	# is_velocity_nonzero refers to last frame
	if (is_velocity_nonzero) and (not is_moving_now):
		# just stopped
		if is_safe_touching and (not is_unsafe_touching):
			emit_signal("parked")
	
	elif (not is_velocity_nonzero) and (is_moving_now):
		# Just started moving
		if is_safe_touching and (not is_unsafe_touching):
			emit_signal("moved")
	
	is_velocity_nonzero = is_moving_now # update is_velocity_nonzero
	
	
	var ang_vel = angular_velocity.length_squared()
	if (ang_vel > 100000.0):
		angular_velocity = Vector3.ZERO
		emit_signal("crashed", ang_vel)
	
	last_linear_velocity = linear_velocity
	last_angular_velocity = angular_velocity
	_process_frame_count += 1



func request_energy(energy_type: String, amount: float) -> bool:
	if (not energy_type in energy_budget_frame) or (not energy_type in available_energy):
		return false
	
	var new_budget = energy_budget_frame[energy_type] + amount
	if (available_energy[energy_type] < new_budget):
		return false
	else:
		energy_budget_frame[energy_type] = new_budget
		return true


func consume_energy_budget():
	for energy_type in energy_budget_frame:
		var this_budget = energy_budget_frame[energy_type]
		if this_budget > 0:
			var energy_conts = energy_containers_by_type[energy_type]
			for this_container in energy_conts:
				if this_container.ContainerActive:
					# Containers are depleted proportionally to what they have
					var this_ratio = this_container.current_level / available_energy[energy_type]
					this_container.consume_energy(this_budget * this_ratio)


func load_energy(energy_type: String, value: float) -> bool:
	# Returns true when full
	if not energy_type in energy_containers_by_type:
		return false
	
	var selected_energy_containers = energy_containers_by_type[energy_type]
	
	# Count only active containers
	var number_of_containers = 0
	for this_container in selected_energy_containers:
		if this_container.ContainerActive:
			number_of_containers += 1
	
	if number_of_containers == 0:
		return true # Full (as in, nothing else to fill at the moment)
	
	#var number_of_containers = selected_energy_containers.size()
	var amount_per_container = value / number_of_containers
	var is_at_least_one_container_not_full = false
	for this_container in selected_energy_containers:
		if this_container.ContainerActive:
			if not this_container.load_energy(amount_per_container): # returns true when full
				is_at_least_one_container_not_full = true
	return (not is_at_least_one_container_not_full)

func land(landing_velocity: float, impact_velocity: float):
	if landing_velocity > MaxLandingForce:
		crash(landing_velocity)

func crash(impact_velocity: float):
	emit_signal("crashed", impact_velocity)







