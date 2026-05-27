# LOST ECO — V Gamer Fair Edition (Implementación completa)

## Ejecutar demo del jurado

**Proyecto → Ejecutar (F5)** con escena principal del menú, o directamente:

`res://scenes/core/pantano_world.tscn`

- **Jugar** → campaña desde Zona 1 (`SettingsManager.GAME_SCENE`)
- **El Pantano** → demo plataformero (`SettingsManager.DEMO_PANTANO_SCENE`)

## Controles

| Tecla | Acción |
|-------|--------|
| A / D | Movimiento |
| Espacio | Salto (coyote **0.15s**, buffer, altura variable) |
| Shift | Dash (gravedad congelada) |
| J | Pulso de Luz |
| ESC | Pausa |
| F1 | Alto contraste (Sobel pantalla completa) |

## Rúbrica universitaria

- **Sin Singleton en gameplay:** `GameSession`, `EnemyFactory`, FSM y HUD inyectados en `pantano_world.tscn`
- **Observer:** señales Godot entre sistemas
- **5+ clases TAD:** ver tabla en repositorio `scripts/core/`
- **State Pattern:** sin `match` en la FSM — polimorfismo en cada estado
- **Factory Method:** `EnemyFactory.gd`

## Shaders (producción)

| Archivo | Función |
|---------|---------|
| `shaders/vignette_screen.gdshader` | Viñeta elíptica, pulso temporal, tinte índigo |
| `shaders/death_bleed.gdshader` | Monocromo + aberración cromática + viñeta de muerte |
| `shaders/edge_detect_high_contrast.gdshader` | Sobel 3×3 accesibilidad |

## Dificultad

- 3 vidas, 14+ picos procedurales, 7 plataformas colapsables, 5 Ecos extra
- Oleadas de enemigos cada ~22s (`EnemyFactory.spawn_jury_encounter`)
- 5 sombras + 2 stalkers iniciales con frases de cyberbullying

## Iluminación

- `LightTextureFactory.gd` genera texturas radiales
- Halo jugador: `PointLight2D` pulsante según energía de luz
- Ojos enemigos: `PointLight2D` carmesí
