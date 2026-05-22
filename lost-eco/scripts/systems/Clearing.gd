extends Node2D

const TS = 16
const FLOOR_COLOR = Color(0.25, 0.40, 0.20)
const TREE_COLOR  = Color(0.10, 0.25, 0.08)

var phase: int = 0
var mateo: Node2D = null
var dialogue_lines = [
	"Mateo: ¡Aléjate de mí!",
	"Alex: Mateo... espera. No voy a hacerte daño.",
	"Alex: Tiré el arma. Mira.",
	"Mateo: ...¿Por qué estás aquí?",
	"Alex: Porque me equivoqué. Porque lo que te hice estuvo mal.",
	"Alex: Estos días en el bosque sentí lo que tú sentías cada día.",
	"Alex: El miedo. La soledad. No poder escapar.",
	"Mateo: Entonces... ¿por qué lo hacías?",
	"Alex: Porque era cobarde. Me hacía sentir poderoso. Lo siento, Mateo.",
	"Alex: De verdad lo siento.",
	"Mateo: ...",
	"Mateo: No sé si puedo perdonarte todavía.",
	"Alex: No tienes que hacerlo ahora. Solo... ¿puedes volver a casa?",
	"Mateo: ...*toma la mano de Alex*... Está bien.",
]
var current_line: int = 0
var dialogue_active: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.15, 0.30, 0.10))
	_build_clearing()

	# Forzar a Alex a soltar el arma
	if GameManager.player:
		GameManager.player.has_weapon = false
		GameManager.player.global_position = Vector2(8 * TS, 10 * TS)

	await get_tree().create_timer(1.0).timeout
	_spawn_mateo()

func _build_clearing() -> void:
	# Suelo del claro
	for y in 20:
		for x in 32:
			var pos = Vector2(x * TS, y * TS)
			var poly = Polygon2D.new()
			poly.position = pos
			poly.polygon = PackedVector2Array([
				Vector2(0,0), Vector2(TS,0), Vector2(TS,TS), Vector2(0,TS)
			])
			poly.color = FLOOR_COLOR
			add_child(poly)

	# Árboles alrededor
	for x in 32:
		_tree(Vector2(x * TS, 0))
		_tree(Vector2(x * TS, 19 * TS))
	for y in 20:
		_tree(Vector2(0, y * TS))
		_tree(Vector2(31 * TS, y * TS))

func _tree(pos: Vector2) -> void:
	var b = StaticBody2D.new()
	b.global_position = pos + Vector2(TS/2.0, TS/2.0)
	add_child(b)
	var c = CollisionShape2D.new()
	var s = RectangleShape2D.new()
	s.size = Vector2(TS, TS)
	c.shape = s
	b.add_child(c)
	var poly = Polygon2D.new()
	poly.position = pos
	poly.polygon = PackedVector2Array([
		Vector2(0,0), Vector2(TS,0), Vector2(TS,TS), Vector2(0,TS)
	])
	poly.color = TREE_COLOR
	add_child(poly)

func _spawn_mateo() -> void:
	mateo = Node2D.new()
	mateo.global_position = Vector2(16 * TS, 10 * TS)
	add_child(mateo)

	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-6,-10), Vector2(6,-10), Vector2(6,8), Vector2(-6,8)
	])
	poly.color = Color(0.7, 0.4, 0.3)
	mateo.add_child(poly)

	# Área de diálogo
	var area = Area2D.new()
	area.global_position = mateo.global_position
	add_child(area)
	var c = CollisionShape2D.new()
	var s = CircleShape2D.new()
	s.radius = 25
	c.shape = s
	area.add_child(c)
	area.body_entered.connect(func(body):
		if body.is_in_group("player") and not dialogue_active:
			dialogue_active = true
			_run_dialogue()
	)

	DialogueManager.show_floating_text(
		"Mateo está ahí... Acércate sin correr.",
		Vector2(80, 20), Color(1.0, 0.9, 0.6)
	)

func _run_dialogue() -> void:
	if current_line >= dialogue_lines.size():
		_ending()
		return
	DialogueManager.show_floating_text(
		dialogue_lines[current_line],
		Vector2(320, 140), Color(1.0, 1.0, 1.0)
	)
	current_line += 1
	await get_tree().create_timer(3.5).timeout
	dialogue_active = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not dialogue_active:
		dialogue_active = true
		_run_dialogue()

func _ending() -> void:
	# Cambio de paleta a tonos cálidos
	var tween = create_tween()
	tween.tween_method(
		func(c: Color): RenderingServer.set_default_clear_color(c),
		Color(0.15, 0.30, 0.10),
		Color(0.95, 0.80, 0.50), 4.0
	)
	tween.tween_callback(func():
		DialogueManager.show_floating_text(
			"Ambos caminaron hacia casa con el amanecer.\nFin.",
			Vector2(320, 300), Color(1.0, 0.9, 0.6)
		)
	)
	# Mover a Mateo junto a Alex
	if mateo and GameManager.player:
		var t2 = create_tween()
		t2.tween_property(mateo, "global_position",
			GameManager.player.global_position + Vector2(20, 0), 2.0)
