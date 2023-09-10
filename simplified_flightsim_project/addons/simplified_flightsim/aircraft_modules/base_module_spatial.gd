##############################################################################
#  BASE CLASS FOR SPATIAL AIRCRAFT MODULES
# ---------------------------------------------------------------------------
#
# All aircraft modules which need 3D coordinates must inherit this class, 
# and all *MUST* implement the setup(aircraft_node) method. 
# All must be placed as direct children of # an Aircraft node. 
# The properties ReceiveInput, ProcessPhysics and
# ProcessRender, if set, should be set in _ready().
#
# All modules which receive input (ReceiveInput=true) *MUST* have the
# receive_input(event) method implemented (not to be confused with the
# built-in input handling like _input(event), _unhandled_input(event), etc
# which *MUST NOT* be implemented)
#
# All modules which process physics (ProcessPhysics=true) *MUST* have
# the process_physic_frame(delta) implemented (not to be confused with
# the built-in _physics_process(delta) which *MUST NOT* be implemented)
#
# All modules which process visuals/cameras (ProcessRender=true) *MUST*
# have the process_render_frame(delta) method implemented (not to be confused
# with the built-in _process(delta) which *MUST NOT* be implemented)
#
# ModuleType is optional and is a String tag used by other modules to find
# this one. E.g. if all engines have ModuleType="engine", any module can
# find the engine modules by searching for modules with ModuleType == "engine"
# ModuleType must be set in _ready()
# The same applies to ModuleTags, except being an Array of String
#
# The order processing between modules is the scene tree order, and within 
# a same module:
#     setup() is called from Aircraft setup
#     receive_input() is called in sync with the Aircraft's _unhandled_input
#     process_physic_frame() is called in sync with Aircraft's _physics_process
#     process_render_frame() is called in sync with Aircraft's _process


@icon("res://addons/simplified_flightsim/aircraft_modules/AircraftModule_Spatial_icon.png")
class_name AircraftModuleSpatial
extends Node3D

@export var ReceiveInput: bool = false
@export var ProcessPhysics: bool = false
@export var ProcessRender: bool = false
@export var ModuleType: String = ""
@export var ModuleTags = [] # (Array, String)
@export var UsesEnergy: bool = false
@export var EnergyType: String = "fuel"

var aircraft = null

func setup(aircraft_node):
	aircraft = aircraft_node

#func receive_input(event):
#	pass

#func process_physic_frame(delta):
#	pass

#func process_render_frame(delta):
#	pass
