extends RefCounted
class_name MenuHelpers
## Utilidades compartidas entre estados del menú (botones, presentación, señales).

const MENU_BUTTON_SCRIPT := preload("res://scripts/menu/menu_button.gd")


static func apply_menu_entry_presentation() -> void:
	SettingsManager.apply_display_settings()
	AudioManager.play_menu_music()
	SceneTransition.fade_in()


static func find_buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in root.get_children():
		if child is Button:
			buttons.append(child)
		buttons.append_array(find_buttons(child))
	return buttons


static func prepare_menu_button(button: Button) -> void:
	if button.get_script() != MENU_BUTTON_SCRIPT:
		button.set_script(MENU_BUTTON_SCRIPT)
		if button.has_method("_ready"):
			button._ready()


static func normalize_key(node_name: String, node_text: String) -> String:
	var raw := node_name if node_text.is_empty() else node_text
	return raw.strip_edges().to_lower()


static func track_connection(connections: Array, source: Object, signal_name: StringName, callable: Callable) -> void:
	if not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)
	connections.append({"source": source, "signal": signal_name, "callable": callable})


static func disconnect_all(connections: Array) -> void:
	for entry in connections:
		var source: Object = entry["source"]
		var signal_name: StringName = entry["signal"]
		var callable: Callable = entry["callable"]
		if is_instance_valid(source) and source.is_connected(signal_name, callable):
			source.disconnect(signal_name, callable)
	connections.clear()
