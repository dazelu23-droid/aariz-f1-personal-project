extends Node3D

## Starter scene for the Kenney asset library project.
## Open the FileSystem dock and browse res://assets/ to drag models into scenes.

const ASSET_PACKS := [
	"car-kit",
	"city-kit-commercial",
	"city-kit-roads",
	"development-essentials",
	"graveyard-kit",
	"mini-skate",
	"nature-kit",
	"pattern-pack-lines",
	"racing-kit",
	"retro-fantasy-kit",
	"space-kit",
]

const DEMO_MODEL := "res://assets/racing-kit/Models/OBJ format/roadStraight.obj"


func _ready() -> void:
	print("Racing Game — Kenney assets loaded.")
	print("Asset packs in res://assets/: ", ", ".join(ASSET_PACKS))
	_load_demo_model()


func _load_demo_model() -> void:
	if not ResourceLoader.exists(DEMO_MODEL):
		push_warning("Demo model not found yet (import may still be running): %s" % DEMO_MODEL)
		return

	var resource := load(DEMO_MODEL)
	if resource is PackedScene:
		add_child((resource as PackedScene).instantiate())
		print("Loaded demo scene: ", DEMO_MODEL)
	elif resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = resource as Mesh
		add_child(mesh_instance)
		print("Loaded demo mesh: ", DEMO_MODEL)
