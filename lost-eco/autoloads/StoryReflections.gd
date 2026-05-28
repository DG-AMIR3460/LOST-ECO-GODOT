extends Node
## Textos temáticos sobre bullying para ecos, eventos y fin de zona.


func get_echo_reflection(zone: int, echo_index: int) -> Dictionary:
	var key := "zone%d_echo_%d" % [zone, echo_index]
	return _REFLECTIONS.get(key, {})


func get_zone_complete(zone: int) -> Dictionary:
	return _REFLECTIONS.get("zone%d_complete" % zone, {})


func get_enemy_hit() -> Dictionary:
	return _REFLECTIONS.get("enemy_hit", {})


func get_crystal_memory(index: int) -> Dictionary:
	return _REFLECTIONS.get("zone3_memory_%d" % index, {})


const _REFLECTIONS: Dictionary = {
	"zone1_echo_1": {
		"title": "Corriente",
		"body": "El agua sigue fluyendo aunque no mires atrás.\nPero lo que dejaste atrás sigue ahí.",
		"accent": Color(0.50, 0.92, 0.85),
	},
	"zone1_echo_2": {
		"title": "Orilla",
		"body": "A veces hay que cruzar el río\npara encontrar a quien lastimamos.",
		"accent": Color(0.50, 0.92, 0.85),
	},
	"zone1_echo_3": {
		"title": "Última corriente",
		"body": "Perdonarse no es olvidar.\nEs dejar de huir de lo que hicimos.",
		"accent": Color(0.50, 0.92, 0.85),
	},
	"zone1_complete": {
		"title": "Reflexión — Zona 1",
		"body": "Cruzaste el río con paciencia.\nEl camino se abre: aún queda mucho por enfrentar.",
		"accent": Color(0.45, 0.90, 0.75),
	},
	"zone2_echo_1": {
		"title": "Fragmento de memoria",
		"body": "Alguien lloró en el baño. Tú pasaste de largo.\nIgnorar también hace daño.",
		"accent": Color(0.95, 0.82, 0.45),
	},
	"zone2_echo_2": {
		"title": "Eco olvidado",
		"body": "Un apodo cruel repetido cada día.\nPara quien lo recibe, nunca fue un juego.",
		"accent": Color(0.95, 0.82, 0.45),
	},
	"zone2_echo_3": {
		"title": "Voz silenciada",
		"body": "Mateo intentó hablar. Nadie lo escuchó.\nEl silencio del grupo fue cómplice.",
		"accent": Color(0.95, 0.82, 0.45),
	},
	"zone2_echo_4": {
		"title": "Última luz",
		"body": "Cada eco es alguien que pidió ayuda.\nRecogerlos es empezar a escuchar.",
		"accent": Color(0.95, 0.82, 0.45),
	},
	"zone2_complete": {
		"title": "Reflexión — Zona 2",
		"body": "Las palabras que lanzamos sin pensar pueden perseguir a otros por años.\nLa luz no borra el pasado, pero ayuda a ver el daño que causamos.",
		"accent": Color(0.95, 0.90, 0.50),
	},
	"zone3_echo_1": {
		"title": "Paso pesado",
		"body": "El remordimiento frena más que el barro.\nReconocerlo es el primer paso.",
		"accent": Color(0.65, 0.95, 0.50),
	},
	"zone3_echo_2": {
		"title": "Paciencia",
		"body": "Sanar no es instantáneo.\nQuien sufre necesita tiempo, no prisa.",
		"accent": Color(0.65, 0.95, 0.50),
	},
	"zone3_echo_3": {
		"title": "Puente",
		"body": "Construir puentes cuesta más que levantar muros.\nPero es la única forma de volver.",
		"accent": Color(0.65, 0.95, 0.50),
	},
	"zone3_complete": {
		"title": "Reflexión — Zona 3",
		"body": "Aprendiste que la empatía no es debilidad.\nEs atreverse a quedarse cuando huir sería más fácil.",
		"accent": Color(0.55, 0.95, 0.45),
	},
	"zone4_echo_1": {
		"title": "Espejo roto",
		"body": "A veces el agresor también tiene miedo.\nReconocerlo no justifica el daño.",
		"accent": Color(0.82, 0.62, 1.0),
	},
	"zone4_echo_2": {
		"title": "Reflejo",
		"body": "El monstruo imita lo que ve.\n¿Qué aprendió de ti en la escuela?",
		"accent": Color(0.82, 0.62, 1.0),
	},
	"zone4_echo_3": {
		"title": "Miedo propio",
		"body": "La violencia escondía tu inseguridad.\nSoltar el arma es elegir otra forma de ser.",
		"accent": Color(0.82, 0.62, 1.0),
	},
	"zone3_memory_1": {
		"title": "Cristal 1",
		"body": "Un mensaje borrado en el grupo:\n«solo es broma». Para Mateo no lo fue.",
		"accent": Color(0.72, 0.88, 1.0),
	},
	"zone3_memory_2": {
		"title": "Cristal 2",
		"body": "La risa del pasillo cuando alguien tropezó.\nTú también reíste. El cristal no olvida.",
		"accent": Color(0.72, 0.88, 1.0),
	},
	"zone3_memory_3": {
		"title": "Cristal 3",
		"body": "«No te metas» — dijiste para no molestar al grupo.\nElegir comodidad también lastima.",
		"accent": Color(0.72, 0.88, 1.0),
	},
	"zone4_complete": {
		"title": "Reflexión — Zona 4",
		"body": "El monstruo era tu propio miedo reflejado.\nElegir la empatía sobre el ataque es el camino de regreso.",
		"accent": Color(1.0, 0.85, 0.35),
	},
	"enemy_hit": {
		"title": "Sombras del acoso",
		"body": "Esta sombra es el peso de las palabras.\nEl bullying deja marcas que no siempre se ven.",
		"accent": Color(1.0, 0.40, 0.35),
	},
}
