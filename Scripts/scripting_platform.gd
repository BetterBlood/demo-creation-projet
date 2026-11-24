extends Node3D

## Vitesse de la plateforme en mètres par seconde
@export var speed: float = 4.0
## Noeud contenant les Marker3D (dans l'ordre de passage)
@export var path: Node3D
## Plateforme à déplacer
@onready var platform: AnimatableBody3D = $Platform

var _points: Array[Vector3] = []
var _cumulative: Array[float] = []
var _total_length: float = 0.0
var _distance: float = 0.0


func _ready() -> void:
	if path == null:
		path = get_node_or_null("Path")

	if path == null:
		push_warning("%s : aucun noeud Path trouvé." % name)
		set_physics_process(false)
		return

	# Récupération des positions monde des markers
	for child in path.get_children():
		if child is Marker3D:
			_points.append(child.global_position)

	if _points.size() < 2:
		push_warning("%s : il faut au moins 2 markers." % name)
		set_physics_process(false)
		return

	# Calcul des longueurs (y compris le segment de retour dernier -> premier)
	for i in _points.size():
		_cumulative.append(_total_length)
		var next := _points[(i + 1) % _points.size()]
		_total_length += _points[i].distance_to(next)

	platform.global_position = _points[0]


func _physics_process(delta: float) -> void:
	if _total_length <= 0.0:
		return

	# Avance à vitesse constante et boucle
	_distance = fposmod(_distance + speed * delta, _total_length)

	# Trouve le segment courant
	var i := _points.size() - 1
	while _cumulative[i] > _distance:
		i -= 1

	var start := _points[i]
	var end := _points[(i + 1) % _points.size()]
	var segment_length := start.distance_to(end)
	var t := (_distance - _cumulative[i]) / segment_length if segment_length > 0.0 else 0.0

	platform.global_position = start.lerp(end, t)
