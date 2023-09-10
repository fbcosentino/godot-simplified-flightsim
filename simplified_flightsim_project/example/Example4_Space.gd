extends Node3D


var template_explosion = preload("res://example/scenes/Explosion/Explosion.tscn")


@export var RefuelRate: float = 20.0

@onready var aircraft = get_node("Aircraft")

var is_reloading_fuel = false

var is_on_planet = false
var planet_influence_radius = null
var planet_density = 1.0

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


func _on_Aircraft_moved():
	# Started moving, if reloading fuel, stop
	if is_reloading_fuel:
		is_reloading_fuel = false
		print("REFUEL STOPPED")

func _process(_delta):
	if is_instance_valid(aircraft):
		$Interface/StagTemp.text = "Stagnation temperature: %.03f" % (aircraft.stagnation_temperature_K - aircraft.ZERO_C_IN_K)

func _physics_process(delta):
	if is_instance_valid(aircraft):
		
		# Refuel at stations
		var is_aircraft_full
		if is_reloading_fuel:
			var amount_per_second = RefuelRate
			is_aircraft_full = aircraft.load_energy("fuel", amount_per_second * delta)
			if is_aircraft_full:
				is_reloading_fuel = false
				print("REFUEL COMPLETE")

func _on_Aircraft_atmospheric_calculations_requested():
	air_calculate_density_temperature()

func air_calculate_density_temperature():
	# Changing air temperature and density is game responsability, not aircraft's
	
	if is_on_planet:
		var planet_surface_radius = aircraft.SeaLevelFromOrigin
		var atmosphere_height = planet_influence_radius - planet_surface_radius
		var altitude_normalized_to_atmosphere = clamp(aircraft.local_altitude / atmosphere_height, 0.0, 1.0)
		
		aircraft.AirTemperature = lerp(25.0, -aircraft.ZERO_C_IN_K, altitude_normalized_to_atmosphere)
		aircraft.AirDensity = 1.0 - altitude_normalized_to_atmosphere
		aircraft.Gravity = 1.0 - altitude_normalized_to_atmosphere
	
	else:
		aircraft.AirTemperature = -aircraft.ZERO_C_IN_K
		aircraft.AirDensity = 0.0
		aircraft.Gravity = 0.0

func _on_Planet1_body_entered(body):
	if body == aircraft:
		switch_to_planet($Planet1)

func _on_Planet2_body_entered(body):
	if body == aircraft:
		switch_to_planet($Planet2)

func _on_Planet1_body_exited(body):
	if body == aircraft:
		switch_to_planet(null)

func switch_to_planet(planet = null):
	# Setting these outside _on_Aircraft_atmospheric_calculations_requested()
	# is only safe because we are setting them as zero at the zero boundary
	# and only once, not every frame
	if not planet:
		is_on_planet = false
		planet_influence_radius = null
		aircraft.AltitudeEnabled = false
		aircraft.AirDensity = 0.0
		aircraft.AirTemperature = -aircraft.ZERO_C_IN_K
		aircraft.Gravity = 0.0
		aircraft.world_ref = aircraft.internal_world_reference
	else:
		is_on_planet = true
		planet_influence_radius = planet.get_node("InfluenceDistance").shape.radius
		aircraft.AltitudeEnabled = true
		aircraft.AirDensity = 0.0
		aircraft.AirTemperature = -aircraft.ZERO_C_IN_K
		aircraft.Gravity = 0.0
		aircraft.world_ref = planet
		aircraft.SeaLevelFromOrigin = planet.get_node("Sphere").mesh.radius
		planet_density = 1.0 if planet == $Planet1 else 3.0
		print("Entering planet")








func _on_BtnBack_pressed():
	get_tree().change_scene_to_file("res://example/ExampleList.tscn")
