extends Node3D


var template_explosion = preload("res://example/scenes/Explosion/Explosion.tscn")

@export var TemperatureAltitudeDropRate: float = 0.0065 # per meter
@export var AltitudeOfZeroDensity: float = 100000.0 # in meters
@export var RefuelRate: float = 20.0

@onready var aircraft = get_node("Aircraft")

var is_reloading_fuel = false
var is_charging_battery = false

func _on_Aircraft_crashed(_impact_velocity):
	var new_explosion = template_explosion.instantiate()
	add_child(new_explosion)
	new_explosion.global_transform.origin = $Aircraft.global_transform.origin
	new_explosion.explode()
	aircraft.queue_free()
	await get_tree().create_timer(2.0).timeout
	var __= get_tree().reload_current_scene()


func _on_Aircraft_parked():
	print("PARKED")
	if $FuelArea.overlaps_body(aircraft):
		# Parked on runway - refuel
		is_reloading_fuel = true
		print("RELOADING FUEL")
	
	if $BatteryArea.overlaps_body(aircraft):
		# Parked on charger
		is_charging_battery = true
		print("RECHARGING BATTERY")

func _on_Aircraft_moved():
	# Started moving, if reloading fuel, stop
	if is_reloading_fuel:
		is_reloading_fuel = false
		print("REFUEL STOPPED")
	if is_charging_battery:
		is_charging_battery = false
		print("CHARGE STOPPED")

func _physics_process(delta):
	if is_instance_valid(aircraft):
		# Changing air temperature and density is game responsability, not aircraft's
		
		# Air Temperature
		#aircraft.AirTemperature = 25.0 - aircraft.local_altitude*TemperatureAltitudeDropRate
		
		# Density is linear towards limit
		#var altitude_progress_towards_limit_normalized = clamp(aircraft.local_altitude / AltitudeOfZeroDensity, 0.0, 1.0) # 1.0 when at limit, 0.0 when sea level
		#aircraft.AirDensity = 1.0 - altitude_progress_towards_limit_normalized
		
		# Refuel at stations
		var is_aircraft_full
		if is_reloading_fuel:
			var amount_per_second = RefuelRate
			is_aircraft_full = aircraft.load_energy("fuel", amount_per_second * delta)
			if is_aircraft_full:
				is_reloading_fuel = false
				print("REFUEL COMPLETE")
		if is_charging_battery:
			var charge_per_second = RefuelRate
			is_aircraft_full = aircraft.load_energy("battery", charge_per_second * delta)
			if is_aircraft_full:
				is_charging_battery = false
				print("CHARGE COMPLETE")


func _on_BtnBack_pressed():
	get_tree().change_scene_to_file("res://example/ExampleList.tscn")
