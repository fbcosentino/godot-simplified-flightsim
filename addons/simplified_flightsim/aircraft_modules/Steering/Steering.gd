extends AircraftModule
class_name AircraftModule_Steering

signal update_interface(values)

enum SteeringTypes {
	AIR_PASSIVE, # Ailerons, rudder, anything passive based on air flow
	THRUSTED # Rocket, ions, anything not based on external environment but uses fuel
}
@export var SteeringType: SteeringTypes = SteeringTypes.AIR_PASSIVE

@export var PowerFactor: float = 1.0

# Elevator distance from center
@export var XPointDistance: float = 1.0
# Rudder/thruster distance from center
@export var YPointDistance: float = 0.5
# Aileron/thruster distance from center, both sides
@export var ZPointDistance: float = 1.0

@export var FuelRate: float = 1.0 # Fuel units per second per axis, at max power

# You don't really *need* to use this property, as any node can receive the
# signals. This is just a helper to automatically connect all possible signals
# assigning the node just once 
@export var UINode: NodePath
@onready var ui_node = get_node_or_null(UINode)

# Separate variables instead of a Vector3 for readability and semantic purposes
# as they have completely different meanings
var axis_x = 0.0 # Usually elevators
var axis_y = 0.0 # Usually rudders
var axis_z = 0.0 # Usually ailerons

var energy_failed = false

func _ready():
	ProcessPhysics = true
	ModuleType = "steering"
	#UsesEnergy = true # obsolete, set from inspector
	#EnergyType = "fuel" # obsolete, set from inspector
	
	if ui_node:
		connect("update_interface", Callable(ui_node, "update_interface"))

func setup(aircraft_node):
	aircraft = aircraft_node
	request_update_interface()

func request_update_interface():
	var message = {
		"axis_x": axis_x,
		"axis_y": axis_y,
		"axis_z": axis_z,
		"energy_failed": energy_failed
	}
	emit_signal("update_interface", message)

func process_physic_frame(delta):
	if not aircraft:
		return
	
	var fuel_budget
	
	# =================================
	# Z - AILERONS
	
	if axis_z != 0:
		#if (SteeringType == SteeringTypes.THRUSTED) or UsesEnergy:
		if UsesEnergy:
			fuel_budget = abs(axis_z) * FuelRate * delta
			if not aircraft.request_energy(EnergyType, fuel_budget):
				energy_failed = true
				return
			else:
				energy_failed = false
		
		var force_vector_right = -aircraft.global_transform.basis.y * PowerFactor * axis_z * 0.5
		var force_vector_left = aircraft.global_transform.basis.y * PowerFactor * axis_z * 0.5
		
		# Internally this is always a thruster. If mode is air/passive, it is
		# simply modulated by air density and speed
		if SteeringType == SteeringTypes.AIR_PASSIVE:
			force_vector_right *= aircraft.AirDensity * aircraft.air_velocity
			force_vector_left *= aircraft.AirDensity * aircraft.air_velocity
		
		var thruster_rotated_position_right = aircraft.global_transform.basis.x*ZPointDistance
		aircraft.apply_force(force_vector_right, thruster_rotated_position_right)
		
		var thruster_rotated_position_left = -aircraft.global_transform.basis.x*ZPointDistance
		aircraft.apply_force(force_vector_left, thruster_rotated_position_left)
	
	
	# =================================
	# X - ELEVATOR
	
	if axis_x != 0:
		#if (SteeringType == SteeringTypes.THRUSTED) or UsesEnergy:
		if UsesEnergy:
			fuel_budget = abs(axis_x) * FuelRate * delta
			if not aircraft.request_energy(EnergyType, fuel_budget):
				energy_failed = true
				return
			else:
				energy_failed = false
		
		var force_vector_up = -aircraft.global_transform.basis.y * PowerFactor * axis_x * 0.5
		var force_vector_down = aircraft.global_transform.basis.y * PowerFactor * axis_x * 0.5
			
		# Internally this is always a thruster. If mode is air/passive, it is
		# simply modulated by air density and speed
		if SteeringType == SteeringTypes.AIR_PASSIVE:
			force_vector_up *= aircraft.AirDensity * aircraft.air_velocity
			force_vector_down *= aircraft.AirDensity * aircraft.air_velocity
			
		var thruster_rotated_position_back = aircraft.global_transform.basis.z*XPointDistance
		aircraft.apply_force(force_vector_up, thruster_rotated_position_back)
		
		var thruster_rotated_position_front = -aircraft.global_transform.basis.z*XPointDistance
		aircraft.apply_force(force_vector_down, thruster_rotated_position_front)
	
	
	# =================================
	# Y - RUDDER
	
	if axis_y != 0:
		#if (SteeringType == SteeringTypes.THRUSTED) or UsesEnergy:
		if UsesEnergy:
			fuel_budget = abs(axis_y) * FuelRate * delta
			if not aircraft.request_energy(EnergyType, fuel_budget):
				energy_failed = true
				return
			else:
				energy_failed = false
			
		var force_vector_rleft = -aircraft.global_transform.basis.x * PowerFactor * axis_y * 0.5
		var force_vector_rright = aircraft.global_transform.basis.x * PowerFactor * axis_y * 0.5
			
		# Internally this is always a thruster. If mode is air/passive, it is
		# simply modulated by air density and speed
		if SteeringType == SteeringTypes.AIR_PASSIVE:
			force_vector_rleft *= aircraft.AirDensity * aircraft.air_velocity
			force_vector_rright *= aircraft.AirDensity * aircraft.air_velocity
			
		var thruster_rotated_position_rback = aircraft.global_transform.basis.z*YPointDistance
		var thruster_rotated_position_rfront = -aircraft.global_transform.basis.z*YPointDistance
		
		# Rudder axis positive turns the plane to left (positive rotation on Y axis)
		aircraft.apply_force(force_vector_rleft, thruster_rotated_position_rfront)
		aircraft.apply_force(force_vector_rright, thruster_rotated_position_rback)

func set_x(value: float):
	axis_x = value
	request_update_interface()

func set_y(value: float):
	axis_y = value
	request_update_interface()

func set_z(value: float):
	axis_z = value
	request_update_interface()
