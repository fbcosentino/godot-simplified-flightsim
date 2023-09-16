# The Engine module demonstrates how to deal with timed/animated features
# using Tweens and engine timers

extends AircraftModuleSpatial
class_name AircraftModule_Engine

signal update_interface(values)

@export var PowerFactor: float = 20.0
@export var EnginePosition: Vector3 = Vector3.ZERO # Deprecated, use node's own position instead

@export var EngineSoundLoop: AudioStream
@export var EngineSoundStart: AudioStream
@export var EngineSoundStop: AudioStream

@export var FuelRate: float = 1.0 # Fuel units per second, at max power

# You don't really *need* to use this property, as any node can receive the
# signals. This is just a helper to automatically connect all possible signals
# assigning the node just once 
@export var UINode: NodePath
@onready var ui_node = get_node_or_null(UINode)

var sfx_engine_loop = null
var sfx_engine_start = null
var sfx_engine_stop = null
var sfx_tween
var is_engine_working = false
var current_power = 0.0

var is_engine_changing_state = false

func _ready():
	
	if EngineSoundLoop:
		sfx_engine_loop = AudioStreamPlayer.new()
		add_child(sfx_engine_loop)
		sfx_engine_loop.stream = EngineSoundLoop
	
	if EngineSoundStart:
		sfx_engine_start = AudioStreamPlayer.new()
		add_child(sfx_engine_start)
		sfx_engine_start.stream = EngineSoundStart
	
	if EngineSoundStop:
		sfx_engine_stop = AudioStreamPlayer.new()
		add_child(sfx_engine_stop)
		sfx_engine_stop.stream = EngineSoundStop
	
	if ui_node:
		connect("update_interface", Callable(ui_node, "update_interface"))
	
	ProcessPhysics = true
	ModuleType = "engine"
	UsesEnergy = true
	EnergyType = "fuel"

func setup(aircraft_node):
	aircraft = aircraft_node
	request_update_interface()


func process_physic_frame(delta):
	if aircraft and is_engine_working:
		var fuel_budget = current_power * FuelRate * delta
		if not aircraft.request_energy(EnergyType, fuel_budget):
			engine_stop()
			return
		
		var force_vector = -global_transform.basis.z * PowerFactor * current_power
		
		# Engine position must be in local position but global rotation
		var engine_rotated_position = global_transform.origin - aircraft.global_transform.origin
		aircraft.apply_force(force_vector, engine_rotated_position)


# -----------------------------------------------------------------------------

func request_update_interface():
	var message = {
		"engine_active": is_engine_working,
		"engine_power": current_power
	}
	emit_signal("update_interface", message)

func power_to_pitch(value: float) -> float:
	return 0.2 + value*0.8

func engine_start():
	print("engine start")
	if is_engine_changing_state:
		return
	
	is_engine_changing_state = true
	
	if not is_engine_working:
		sfx_engine_loop.volume_db = -40
		sfx_engine_loop.pitch_scale = 0.2
	
	if sfx_tween:
		sfx_tween.kill()
	sfx_tween = create_tween()
	sfx_tween.tween_property(sfx_engine_loop, "volume_db", 1.0, 1.0)
	sfx_tween.tween_property(sfx_engine_loop, "pitch_scale", power_to_pitch(current_power), 1.0)
	sfx_engine_loop.play()
	
	sfx_engine_start.play()
	
	await get_tree().create_timer(1.0).timeout
	
	is_engine_working = true
	request_update_interface()
	
	is_engine_changing_state = false

func engine_stop():
	if is_engine_changing_state:
		return
	
	if not is_engine_working:
		return
	
	is_engine_changing_state = true

	is_engine_working = false
	current_power = 0.0
	
	request_update_interface()
	
	if sfx_tween:
		sfx_tween.kill()
	sfx_tween = create_tween()
	sfx_tween.tween_property(sfx_engine_loop, "pitch_scale", power_to_pitch(0.0), 1.0)
	
	await sfx_tween.finished
	
	sfx_tween = create_tween()
	sfx_tween.tween_property(sfx_engine_loop, "volume_db", 1.0, 1.0)
	
	await get_tree().create_timer(1.0).timeout
	sfx_engine_loop.stop()
	request_update_interface()
	
	is_engine_changing_state = false

func engine_set_power(value: float):
	if is_engine_changing_state:
		return
	
	if not is_engine_working:
		return
	
	is_engine_changing_state = true

	current_power = value
	
	request_update_interface()
	
	is_engine_changing_state = false
	
	if sfx_tween:
		sfx_tween.kill()
	sfx_tween = create_tween()
	sfx_tween.tween_property(sfx_engine_loop, "volume_db", 1.0, 0.3).set_trans(Tween.TRANS_LINEAR)
	sfx_tween.parallel().tween_property(sfx_engine_loop, "pitch_scale", power_to_pitch(current_power), 0.3).set_trans(Tween.TRANS_LINEAR)



func engine_increase_power(step: float):
	var new_value = clamp(current_power + step, 0.0, 1.0)
	if new_value != current_power:
		engine_set_power(new_value)
