extends Node
## Debug logging system that writes to separate files per feature
## Allows testing without console spam

const LOGS_ENABLED: bool = false  # Master toggle - Disabled for normal gameplay
const LOG_DIR: String = "user://debug_logs/"

var log_files: Dictionary = {}  # category: FileAccess

func _ready() -> void:
	if not LOGS_ENABLED:
		return

	# Create logs directory
	DirAccess.make_dir_absolute(LOG_DIR)

	# Clear old logs on startup
	clear_all_logs()

	print("DebugLogger initialized - logs will be saved to: ", LOG_DIR)

func log(category: String, message: String) -> void:
	"""Write a log message to a specific category file"""
	if not LOGS_ENABLED:
		return

	# Also print to console for immediate feedback
	print("[", category, "] ", message)

	# Get or create file for this category
	var file: FileAccess
	if category in log_files:
		file = log_files[category]
	else:
		var file_path = LOG_DIR + category + ".txt"
		file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			log_files[category] = file
			# Write header
			file.store_line("===========================================")
			file.store_line("DEBUG LOG: " + category)
			file.store_line("Started: " + Time.get_datetime_string_from_system())
			file.store_line("===========================================")
			file.store_line("")
		else:
			push_error("Failed to create log file: " + file_path)
			return

	# Write timestamped message
	var timestamp = "[%.2f] " % (Time.get_ticks_msec() / 1000.0)
	file.store_line(timestamp + message)
	file.flush()  # Ensure it's written immediately

func clear_all_logs() -> void:
	"""Delete all existing log files"""
	if not LOGS_ENABLED:
		return

	var dir = DirAccess.open(LOG_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".txt"):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func _exit_tree() -> void:
	"""Close all log files on exit"""
	for file in log_files.values():
		if file:
			file.close()
