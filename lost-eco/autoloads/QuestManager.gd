extends Node

signal quest_updated(quest_id: String, stage: int)
signal quest_completed(quest_id: String)

var quest_data: Dictionary = {
	"zone1": {"stage": 0, "max_stage": 3, "completed": false},
	"zone2": {"stage": 0, "max_stage": 3, "completed": false},
	"zone3": {"stage": 0, "max_stage": 1, "completed": false},
	"zone4": {"stage": 0, "max_stage": 3, "completed": false},
	"memories_collected": 0,
	"total_memories": 8,
}

func get_quest_stage(quest_id: String) -> int:
	return quest_data.get(quest_id, {}).get("stage", 0)

func advance_quest(quest_id: String) -> void:
	if not quest_data.has(quest_id):
		return
	var q = quest_data[quest_id]
	if q["stage"] < q["max_stage"]:
		q["stage"] += 1
		quest_updated.emit(quest_id, q["stage"])
		if q["stage"] >= q["max_stage"]:
			q["completed"] = true
			quest_completed.emit(quest_id)

func collect_memory() -> void:
	quest_data["memories_collected"] += 1
	quest_updated.emit("memories", quest_data["memories_collected"])

func all_zones_complete() -> bool:
	return (quest_data["zone1"]["completed"] and
			quest_data["zone2"]["completed"] and
			quest_data["zone3"]["completed"] and
			quest_data["zone4"]["completed"])
