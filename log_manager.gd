extends Node
signal log_added(line: String)
const MAX_LINES = 5
var lines : Array = []
func log(msg: String) -> void:
	print(msg)
	lines.append(msg)
	while lines.size() > MAX_LINES:
		lines.pop_front()
	log_added.emit(msg)
func get_text() -> String:
	var s = ""
	for line in lines:
		s += line + "\n"
	return s
func clear() -> void:
	lines.clear()
	log_added.emit("")
