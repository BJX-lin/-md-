extends Node
# UI

const ThemeBuilder := preload("res://src/ui/theme_builder.gd")
const TitleScreen := preload("res://src/ui/title_screen.gd")
const SplashScreen := preload("res://src/ui/splash_screen.gd")
const GameScreen := preload("res://src/ui/game_screen.gd")
const EndingScreen := preload("res://src/ui/ending_screen.gd")

var root_ui: Control
var current: Control

func _ready() -> void:
	get_window().min_size = Vector2i(640, 360)
	var theme := ThemeBuilder.build()
	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.theme = theme
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ui)
	# Engine
	# Splash
	var sp := SplashScreen.new()
	sp.finished.connect(goto_title)
	_switch(sp)

func _switch(node: Control) -> void:
	if current and is_instance_valid(current):
		current.queue_free()
	current = node
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(node)

func goto_title() -> void:
	var t := TitleScreen.new()
	t.start_new.connect(_on_start_new)
	t.continue_game.connect(_on_continue)
	t.load_slot.connect(_on_load_slot)
	t.start_extra.connect(_on_start_extra)
	_switch(t)

func _on_start_new() -> void:
	GameState.reset_run()
	var g := GameScreen.new()
	g.finished.connect(_on_story_finished)
	g.quit_to_title.connect(goto_title)
	_switch(g)
	g.begin("prologue")

func _on_start_extra() -> void:
	GameState.reset_run()
	var g := GameScreen.new()
	g.finished.connect(_on_story_finished)
	g.quit_to_title.connect(goto_title)
	_switch(g)
	g.begin("extra_sunny_day")

func _on_continue() -> void:
	var d := SaveSystem.read_autosave()
	if d.is_empty():
		_on_start_new()
		return
	_load_payload(d)

func _on_load_slot(i: int) -> void:
	var d := SaveSystem.read_slot(i)
	if d.is_empty():
		return
	_load_payload(d)

func _load_payload(d: Dictionary) -> void:
	GameState.from_dict(d)
	var g := GameScreen.new()
	g.finished.connect(_on_story_finished)
	g.quit_to_title.connect(goto_title)
	_switch(g)
	var node := String(d.get("node", "prologue"))
	g.begin(node if StoryEngine.has_story_node(node) else "prologue")
	# Save/Load

	g.restore_scene()

func _on_story_finished(ending_id: String) -> void:
	var e := EndingScreen.new()
	e.ending_id = ending_id
	e.back_to_title.connect(goto_title)
	_switch(e)
