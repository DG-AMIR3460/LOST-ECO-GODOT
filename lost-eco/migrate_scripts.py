#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reorganiza scripts/ en 5 carpetas: personaje, mapa, enemigos, menu, puntuacion
+ cinematicas y npcs quedan intactos/consolidados.
Actualiza TODAS las referencias en .gd y .tscn automáticamente.
"""
import os, shutil, re

ROOT = r"C:\Users\amirs\Desktop\LOST ECO GODOT\lost-eco"

# ── Mapa old_rel → new_rel ──────────────────────────────────────────────────
MOVES = {
    # PERSONAJE ──────────────────────────────────────────────────────────────
    "scripts/player/Alex.gd":
        "scripts/personaje/Alex.gd",
    "scripts/core/player/PlayerController2D.gd":
        "scripts/personaje/PlayerController2D.gd",
    "scripts/core/player/PlayerStateMachine.gd":
        "scripts/personaje/PlayerStateMachine.gd",
    "scripts/core/player/PlayerState.gd":
        "scripts/personaje/PlayerState.gd",
    "scripts/core/player/PlayerSkinMapper.gd":
        "scripts/personaje/PlayerSkinMapper.gd",
    "scripts/core/player/LightPulseWave.gd":
        "scripts/personaje/LightPulseWave.gd",
    "scripts/visual/GothicPlayerVisual.gd":
        "scripts/personaje/GothicPlayerVisual.gd",
    "scripts/visual/PlayerAnimationFactory.gd":
        "scripts/personaje/PlayerAnimationFactory.gd",
    "scripts/systems/CharacterArt.gd":
        "scripts/personaje/CharacterArt.gd",
    "scripts/systems/CharacterSpritesData.gd":
        "scripts/personaje/CharacterSpritesData.gd",
    # estados del jugador
    "scripts/core/player/states/IdleState.gd":
        "scripts/personaje/estados/IdleState.gd",
    "scripts/core/player/states/MoveState.gd":
        "scripts/personaje/estados/MoveState.gd",
    "scripts/core/player/states/JumpState.gd":
        "scripts/personaje/estados/JumpState.gd",
    "scripts/core/player/states/DashState.gd":
        "scripts/personaje/estados/DashState.gd",
    "scripts/core/player/states/AttackState.gd":
        "scripts/personaje/estados/AttackState.gd",
    "scripts/core/player/states/HurtState.gd":
        "scripts/personaje/estados/HurtState.gd",
    "scripts/core/player/states/DeadState.gd":
        "scripts/personaje/estados/DeadState.gd",

    # MAPA ───────────────────────────────────────────────────────────────────
    "scripts/systems/Zone1_Labyrinth.gd":
        "scripts/mapa/Zone1_Labyrinth.gd",
    "scripts/systems/Zone2_Swamp.gd":
        "scripts/mapa/Zone2_Swamp.gd",
    "scripts/systems/Zone3_Cave.gd":
        "scripts/mapa/Zone3_Cave.gd",
    "scripts/systems/Zone4_Rio.gd":
        "scripts/mapa/Zone4_Rio.gd",
    "scripts/systems/Clearing.gd":
        "scripts/mapa/Clearing.gd",
    "scripts/systems/ZoneMinimap.gd":
        "scripts/mapa/ZoneMinimap.gd",
    "scripts/systems/ZoneUIBootstrap.gd":
        "scripts/mapa/ZoneUIBootstrap.gd",
    "scripts/visual/ZoneVisualBootstrap.gd":
        "scripts/mapa/ZoneVisualBootstrap.gd",
    "scripts/visual/GothicTilePainter.gd":
        "scripts/mapa/GothicTilePainter.gd",
    "scripts/visual/GothicAtmosphere.gd":
        "scripts/mapa/GothicAtmosphere.gd",
    "scripts/visual/GothicParallaxLayers.gd":
        "scripts/mapa/GothicParallaxLayers.gd",
    "scripts/core/ui/FogOfWarMinimap.gd":
        "scripts/mapa/FogOfWarMinimap.gd",
    "scripts/core/level/LevelProceduralObstacle.gd":
        "scripts/mapa/LevelProceduralObstacle.gd",
    "scripts/core/level/CollapsingPlatform.gd":
        "scripts/mapa/CollapsingPlatform.gd",
    "scripts/core/level/HiddenSpike.gd":
        "scripts/mapa/HiddenSpike.gd",
    "scripts/core/level/TerrainSwitch.gd":
        "scripts/mapa/TerrainSwitch.gd",
    "scripts/systems/FollowCamera.gd":
        "scripts/mapa/FollowCamera.gd",
    "scripts/core/world/PantanoWorldController.gd":
        "scripts/mapa/PantanoWorldController.gd",
    "scripts/core/world/ParallaxSwampSetup.gd":
        "scripts/mapa/ParallaxSwampSetup.gd",
    "scripts/visual/EchoStarVisual.gd":
        "scripts/mapa/EchoStarVisual.gd",

    # ENEMIGOS ───────────────────────────────────────────────────────────────
    "scripts/core/enemies/EnemyAIBase.gd":
        "scripts/enemigos/EnemyAIBase.gd",
    "scripts/systems/EnemyBehavior.gd":
        "scripts/enemigos/EnemyBehavior.gd",
    "scripts/core/enemies/EnemyFactory.gd":
        "scripts/enemigos/EnemyFactory.gd",
    "scripts/core/enemies/ShadowSwarmEnemy.gd":
        "scripts/enemigos/ShadowSwarmEnemy.gd",
    "scripts/core/enemies/SwampStalkerEnemy.gd":
        "scripts/enemigos/SwampStalkerEnemy.gd",
    "scripts/enemies/MirrorGuardian.gd":
        "scripts/enemigos/MirrorGuardian.gd",
    "scripts/systems/ShadowEnemyVisual.gd":
        "scripts/enemigos/ShadowEnemyVisual.gd",
    "scripts/core/enemies/BullyingProjectile.gd":
        "scripts/enemigos/BullyingProjectile.gd",

    # MENÚ: scripts/menu/ se queda igual; solo movemos lo que estaba fuera
    # (nada extra en este caso)

    # PUNTUACIÓN ─────────────────────────────────────────────────────────────
    "scripts/core/session/GameSession.gd":
        "scripts/puntuacion/GameSession.gd",
    "scripts/visual/PremiumZoneHUD.gd":
        "scripts/puntuacion/PremiumZoneHUD.gd",
    "scripts/core/ui/GameHUD.gd":
        "scripts/puntuacion/GameHUD.gd",
    "scripts/core/ui/HeartIcon.gd":
        "scripts/puntuacion/HeartIcon.gd",
    "scripts/visual/LightPipIcon.gd":
        "scripts/puntuacion/LightPipIcon.gd",
    "scripts/core/level/MemoryEcho.gd":
        "scripts/puntuacion/MemoryEcho.gd",
    "scripts/systems/MemoryFragment.gd":
        "scripts/puntuacion/MemoryFragment.gd",
    "scripts/systems/EchoOfLight.gd":
        "scripts/puntuacion/EchoOfLight.gd",

    # CINEMATICAS ────────────────────────────────────────────────────────────
    "scripts/core/cinematics/DeathCinematicDirector.gd":
        "scripts/cinematicas/DeathCinematicDirector.gd",
    "scripts/core/cinematics/ScreenShake.gd":
        "scripts/cinematicas/ScreenShake.gd",
    "scripts/core/accessibility/AccessibilityManager.gd":
        "scripts/cinematicas/AccessibilityManager.gd",
    "scripts/core/visual/LightTextureFactory.gd":
        "scripts/cinematicas/LightTextureFactory.gd",
}

# Construir el mapa de sustitución de paths "res://old" → "res://new"
PATH_MAP = {
    "res://" + old.replace("\\", "/"): "res://" + new.replace("\\", "/")
    for old, new in MOVES.items()
}


def _replace_all(text: str) -> str:
    """Sustituye todos los res:// paths afectados en un texto."""
    for old, new in PATH_MAP.items():
        text = text.replace(old, new)
    return text


def move_file(old_rel: str, new_rel: str) -> None:
    src = os.path.join(ROOT, old_rel.replace("/", os.sep))
    dst = os.path.join(ROOT, new_rel.replace("/", os.sep))
    if not os.path.exists(src):
        print(f"  [SKIP] no existe: {old_rel}")
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.move(src, dst)
    print(f"  [MV]  {old_rel}  →  {new_rel}")

    # también el .uid compañero si existe
    src_uid = src + ".uid"
    dst_uid = dst + ".uid"
    if os.path.exists(src_uid):
        shutil.move(src_uid, dst_uid)
        print(f"  [MV]  {old_rel}.uid  →  {new_rel}.uid")


def update_file(path: str) -> None:
    """Reescribe el archivo solo si hay cambios."""
    try:
        with open(path, encoding="utf-8") as f:
            original = f.read()
    except Exception:
        return
    updated = _replace_all(original)
    if updated != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(updated)
        rel = os.path.relpath(path, ROOT).replace("\\", "/")
        print(f"  [UPD] {rel}")


def collect_files_to_update():
    """Recoge todos los .gd y .tscn del proyecto (excluye addons)."""
    result = []
    for root, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in ("addons", ".godot", ".git")]
        for f in files:
            if f.endswith((".gd", ".tscn")):
                result.append(os.path.join(root, f))
    return result


# ── PASO 1: mover archivos ────────────────────────────────────────────────────
print("\n=== PASO 1: Moviendo archivos ===")
for old, new in MOVES.items():
    move_file(old, new)

# ── PASO 2: actualizar referencias ───────────────────────────────────────────
print("\n=== PASO 2: Actualizando referencias en .gd y .tscn ===")
for filepath in collect_files_to_update():
    update_file(filepath)

# ── PASO 3: limpiar carpetas vacías antiguas ──────────────────────────────────
print("\n=== PASO 3: Eliminando carpetas vacías ===")
old_dirs = [
    "scripts/player",
    "scripts/core/player/states",
    "scripts/core/player",
    "scripts/core/enemies",
    "scripts/core/level",
    "scripts/core/session",
    "scripts/core/cinematics",
    "scripts/core/accessibility",
    "scripts/core/ui",
    "scripts/core/visual",
    "scripts/core/world",
    "scripts/core",
    "scripts/enemies",
    "scripts/systems",
    "scripts/visual",
]
for d in old_dirs:
    full = os.path.join(ROOT, d.replace("/", os.sep))
    if os.path.isdir(full):
        remaining = [f for f in os.listdir(full) if not f.endswith(".uid")]
        # eliminar carpetas vacías o con solo .uid huérfanos
        try:
            remaining_all = os.listdir(full)
            if not remaining_all:
                os.rmdir(full)
                print(f"  [RM]  {d}/")
            elif all(f.endswith(".uid") for f in remaining_all):
                for f in remaining_all:
                    os.remove(os.path.join(full, f))
                os.rmdir(full)
                print(f"  [RM]  {d}/ (solo .uid huérfanos)")
            else:
                print(f"  [KEEP] {d}/ — quedan: {remaining_all}")
        except OSError as e:
            print(f"  [ERR] {d}: {e}")

print("\n=== Migración completada ===")
print("\nEstructura final de scripts/:")
for root, dirs, files in os.walk(os.path.join(ROOT, "scripts")):
    dirs[:] = sorted([d for d in dirs if d != "__pycache__"])
    level = root.replace(ROOT, "").count(os.sep) - 1
    indent = "  " * level
    folder = os.path.basename(root)
    print(f"{indent}{folder}/")
    subindent = "  " * (level + 1)
    for f in sorted(files):
        if not f.endswith(".uid"):
            print(f"{subindent}{f}")
