extends RefCounted
class_name ZoneMissionBriefs
## Textos de misión al entrar en cada zona (siempre visibles con [E]).


static func show_for_zone(zone_id: int) -> void:
	match zone_id:
		1:
			DialogueManager.show_zone_intro(
				"ZONA 1 — El Río",
				"META: recoger 3 Ecos de Luz (★ en el minimapa).\n\n"
				+ "1) El agua te frena — avanza despacio.\n"
				+ "2) Recoge 3 ecos (★) siguiendo el río.\n"
				+ "3) Con 3/3, la SALIDA (X) abre abajo a la derecha.\n"
				+ "4) Usa [J] si una sombra te bloquea.",
				"[E] ecos  ·  [J] pulso  ·  Revisa el minimapa (esquina)",
				Color(0.45, 0.90, 0.75)
			)
		2:
			DialogueManager.show_zone_intro(
				"ZONA 2 — Laberinto de Palabras",
				"META: recoger 4 Ecos de Luz (★ en el minimapa).\n\n"
				+ "1) Muévete con WASD por el laberinto.\n"
				+ "2) Toca cada eco brillante.\n"
				+ "3) Con 4/4 ecos, la SALIDA (X) se abre abajo a la derecha.\n"
				+ "4) Evita las sombras rojas (-1 vida).",
				"[J] Pulso de luz empuja sombras  ·  [E] interactuar  ·  ESC pausa",
				Color(0.95, 0.90, 0.45)
			)
		3:
			DialogueManager.show_zone_intro(
				"ZONA 3 — El Pantano",
				"META: activar 3 Pilares + recoger 3 Ecos.\n\n"
				+ "1) Busca pilares morados y mantén [E] hasta activarlos.\n"
				+ "2) Recoge 3 ecos (★) por el pantano.\n"
				+ "3) Con todo completo, la SALIDA (X) abre abajo a la derecha.\n"
				+ "4) El fango te frena — camina con calma.",
				"[J] empuja sombras  ·  [E] pilares y ecos  ·  Mira el HUD arriba",
				Color(0.65, 0.95, 0.50)
			)
		4:
			DialogueManager.show_zone_intro(
				"ZONA 4 — Cueva del Espejo",
				"META: 3 cristales + 3 luces + 3 ecos + derrotar al jefe.\n\n"
				+ "1) Cristales AZULES → [E] (lee la memoria).\n"
				+ "2) Círculos DORADOS → [E] (uno está abajo, centro).\n"
				+ "3) Recoge 3 ecos (★).\n"
				+ "4) Baja por el pasillo central a la Sala del Espejo.\n"
				+ "5) Con todo listo: usa [J] cerca del jefe para dañarlo con pulsos de luz.",
				"[J] pulso daña al jefe  ·  [E] cristales y luces  ·  HUD muestra tu progreso",
				Color(0.92, 0.82, 0.40)
			)
		_:
			pass


static func hud_objective(zone_id: int) -> String:
	match zone_id:
		1: return "META: 3 ECOS → SALIDA X"
		2: return "META: 4 ECOS → SALIDA X"
		3: return "META: 3 PILARES + 3 ECOS"
		4: return "META: CRIST+LUCES+ECOS+JEFE"
		_: return ""
