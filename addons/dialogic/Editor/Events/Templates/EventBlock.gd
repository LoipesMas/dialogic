tool
extends HBoxContainer

# customization options for the event 

# This is the default data that is going to be saved to json
export(String) var event_name : String = 'Event name'
export (Dictionary) var event_data: Dictionary = {'event_id':'dialogic_000'}
export(Color) var event_color: Color = Color(0.6,0.6,0.6,1)
export(Texture) var event_icon : Texture

export(PackedScene) var header_scene : PackedScene
export(PackedScene) var body_scene : PackedScene

export (bool) var expand_on_default := false
export (bool) var needs_indentation := false
export (String) var help_page_path := ""
signal option_action(action_name)


### internal node eferences
onready var panel = $PanelContainer
onready var selected_style = $PanelContainer/SelectedStyle
onready var warning = $PanelContainer/MarginContainer/VBoxContainer/Header/Warning
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel
onready var icon_texture  = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel/IconTexture
onready var expand_control = $PanelContainer/MarginContainer/VBoxContainer/Header/ExpandControl
onready var header_content_container = $PanelContainer/MarginContainer/VBoxContainer/Header/Content
onready var body_container = $PanelContainer/MarginContainer/VBoxContainer/Body
onready var body_content_container = $PanelContainer/MarginContainer/VBoxContainer/Body/Content
onready var indent_node = $Indent
onready var help_button = $PanelContainer/MarginContainer/VBoxContainer/Header/HelpButton
var header_node
var body_node

### extarnal node references
var editor_reference

### the indent size
var indent_size = 45
var current_indent_level = 1

# Setting this to true will ignore the event while saving
# Useful for making placeholder events in drag and drop
var ignore_save = false

## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************

func visual_select():
	selected_style.show()


func visual_deselect():
	selected_style.hide()


# called by the timeline before adding it to the tree
func load_data(data):
	event_data = data


func get_body():
	return body_node


func get_header():
	return header_node


func set_warning(text):
	warning.texture = get_icon("NodeWarning", "EditorIcons")
	warning.hint_tooltip = text


func remove_warning(text = ''):
	if warning.hint_tooltip == text or text == '':
		warning.texture = null


func set_preview(text: String):
	expand_control.set_preview(text)


func set_indent(indent: int):
	indent_node.rect_min_size = Vector2(indent_size * indent, 0)
	indent_node.visible = indent != 0
	current_indent_level = indent
	update()


func set_expanded(expanded: bool):
	expand_control.set_expanded(expanded)


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************

func _set_event_icon(icon: Texture):
	icon_texture.texture = icon
	var _scale = DialogicUtil.get_editor_scale(self)
	var cpanel = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer
	var ip = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel
	var ipc = $PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel/IconTexture
	# Change color if light theme
	ipc.self_modulate = Color(1,1,1,1)
	if not get_constant("dark_theme", "Editor"):
		icon_texture.self_modulate = get_color("font_color", "Editor")
	# Resizing the icon acording to the scale
	var icon_size = 38
	cpanel.rect_min_size = Vector2(icon_size, icon_size) * _scale
	ip.rect_min_size = cpanel.rect_min_size
	ipc.rect_min_size = ip.rect_min_size
	#rect_min_size.y = 50 * _scale
	#icon_texture.rect_size = icon_texture.rect_size * _scale
	

func _set_event_name(text: String):
	if event_name == "Text Event":
		var t_label = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel")
		if t_label:
			t_label.queue_free()
	else:
		title_label.text = text


func _set_header(scene: PackedScene):
	header_node = _set_content(header_content_container, scene)


func _set_body(scene: PackedScene):
	body_node = _set_content(body_content_container, scene)
	# show the expand toggle
	expand_control.set_enabled(body_node != null)


func _setup_event():
	if event_icon != null:
		_set_event_icon(event_icon)
	if event_name != null:
		_set_event_name(event_name)
	if header_scene != null:
		_set_header(header_scene)
	if body_scene != null:
		_set_body(body_scene)
	if event_color != null:
		$PanelContainer/MarginContainer/VBoxContainer/Header/CenterContainer/IconPanel.set("self_modulate", event_color)


func _set_content(container: Control, scene: PackedScene):
	for c in container.get_children():
		container.remove_child(c)
	if scene != null:
		var node = scene.instance()
		node.editor_reference = editor_reference
		container.add_child(node)
#		node.set_owner(get_tree().get_edited_scene_root())
		return node
	return null


func _on_ExpandControl_state_changed(expanded: bool):
	if expanded:
		if body_node:
			body_container.show()
	else:
		if body_node:
			body_container.hide()
			expand_control.set_preview(body_node.get_preview())


func _on_OptionsControl_action(action_name: String):
	# Simply transmit the signal to the timeline editor
	emit_signal("option_action", action_name)


func _on_Indent_visibility_changed():
	if not indent_node:
		return
	if needs_indentation:
		if indent_node.visible:
			remove_warning(DTS.translate("This event needs a question event around it!"))
		else:
			set_warning(DTS.translate("This event needs a question event around it!"))


func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		grab_focus() # Grab focus to avoid copy pasting text or events
		if event.doubleclick and expand_control.enabled:
			expand_control.set_expanded(not expand_control.expanded)
	# For opening the context menu
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			$PopupMenu.rect_global_position = get_global_mouse_position()
			var popup = $PopupMenu.popup()


# called when the data of the header is changed
func _on_Header_data_changed(new_event_data):
	event_data = new_event_data
	
	# update the body in case it has to
	if get_body():
		get_body().load_data(event_data)


# called when the data of the body is changed
func _on_Body_data_changed(new_event_data):
	event_data = new_event_data
	
	# update the header in case it has to
	if get_header():
		get_header().load_data(event_data)

func _request_set_body_enabled(enabled:bool):
	expand_control.set_enabled(enabled)
	
	if get_body():
		get_body().visible = enabled
	
func _request_selection():
	var timeline_editor = editor_reference.get_node_or_null('MainPanel/TimelineEditor')
	if (timeline_editor != null):
		# @todo select item and clear selection is marked as "private" in TimelineEditor.gd
		# consider to make it "public" or add a public helper function
		timeline_editor.select_item(self)

## *****************************************************************************
##								OVERRIDES
## *****************************************************************************

func _ready():
	event_name = DTS.translate(event_name)
	
	## DO SOME STYLING
	$PanelContainer/SelectedStyle.modulate = get_color("accent_color", "Editor")
	
	indent_size = indent_size * DialogicUtil.get_editor_scale(self)
	
	_setup_event()
	
	set_focus_mode(1) # Allowing this node to grab focus
	
	# signals
	panel.connect("gui_input", self, '_on_gui_input')
	expand_control.connect("state_changed", self, "_on_ExpandControl_state_changed")
	$PopupMenu.connect("action", self, "_on_OptionsControl_action")
	
	# load icons
	#if help_page_path != "":
	#	help_button.icon = get_icon("HelpSearch", "EditorIcons")
	#	help_button.show()
	
	# when it enters the tree, load the data into the header/body
	# If there is any external data, it will be set already BEFORE the event is added to tree
	# if you have a header
	if get_header():
		get_header().connect("data_changed", self, "_on_Header_data_changed")
		get_header().connect("request_open_body", expand_control, "set_expanded", [true])
		get_header().connect("request_close_body", expand_control, "set_expanded", [false])
		get_header().connect("request_selection", self, "_request_selection")
		get_header().connect("request_set_body_enabled", self, "_request_set_body_enabled")
		get_header().connect("set_warning", self, "set_warning")
		get_header().connect("remove_warning", self, "remove_warning")
		get_header().load_data(event_data)
	# if you have a body
	if get_body():
		get_body().connect("data_changed", self, "_on_Body_data_changed")
		get_body().connect("request_open_body", expand_control, "set_expanded", [true])
		get_body().connect("request_close_body", expand_control, "set_expanded", [false])
		get_body().connect("request_set_body_enabled", self, "_request_set_body_enabled")
		get_body().connect("request_selection", self, "_request_selection")
		get_body().connect("set_warning", self, "set_warning")
		get_body().connect("remove_warning", self, "remove_warning")
		get_body().load_data(event_data)
	
	if get_body():
		set_expanded(expand_on_default)
	
	_on_Indent_visibility_changed()


func _on_HelpButton_pressed():
	if help_page_path:
		var master_tree = editor_reference.get_node_or_null('MainPanel/MasterTreeContainer/MasterTree')
		master_tree.select_documentation_item(help_page_path)


func _draw():
	var timeline_children = get_parent().get_children()
	var timeline_lenght = timeline_children.size()
	var line_color = Color("#4D4D4D")
	var test_color = Color(1,0,0,0.5)
	var _scale = DialogicUtil.get_editor_scale(self)
	var line_width = 3 * _scale
	var pos_x = (27 * _scale)
	var pos_y = 46 * _scale
	
	
	
	# Adjusting the pos_x. Not sure why it is not consistent between render scales
	if _scale == 1.5:
		pos_x -= 3
	if _scale == 1.75:
		pos_x -= 4
	if _scale == 2:
		pos_x -= 6

	# If the event is the last one, don't draw a line aftwards
	if timeline_children[timeline_lenght-1] == self:
		return

	# Figuring out the next event
	var next_event = timeline_children[get_index() + 1]
	
	if current_indent_level > 0:
		# Root (level 0) Vertical Line 
		draw_rect(Rect2(Vector2(pos_x, pos_y - (45 * _scale)),
			Vector2(line_width, rect_size.y + (5 * _scale))),
			line_color, true)
		
		# Todo: previous lines when needed
		
		# Line at current indent
		var line_size = (indent_size * current_indent_level) + (4 * _scale)
		if next_event.event_name != 'End Branch' and event_name != 'Choice':
			if event_name != 'Question' and next_event.event_name == 'Choice':
				# Skip drawing lines before going to the next choice
				pass
			else:
				draw_rect(Rect2(
					Vector2(pos_x + line_size , pos_y),
					Vector2(line_width, rect_size.y - (40 * _scale))),
					line_color, true)
	else:
		# Root (level 0) Vertical Line
		draw_rect(Rect2(Vector2(pos_x, pos_y),
			Vector2(line_width, rect_size.y - (40 * _scale))),
			line_color, true)
			
	# Drawing arc
	if event_name == 'Choice':
		# Connecting with the question 
		var arc_start_x = (indent_size * (current_indent_level)) + (11.2 * _scale)
		var arc_start_y = 0
		var arc_point_count = 12 * _scale
		var arc_radius = 24 * _scale
		var start_angle = 90
		var end_angle = 185
		
		if current_indent_level == 1:
			arc_start_x = (indent_size * (current_indent_level)) + (7.5 * _scale)
		
		draw_arc(
			Vector2(arc_start_x, arc_start_y),
			arc_radius,
			deg2rad(start_angle),
			deg2rad(end_angle),
			arc_point_count, #point count
			line_color,
			line_width - (1 * _scale),
			true
		)

		# Don't draw arc if next event is another choice event
		if next_event.event_name == "Choice" or next_event.event_name == "End Branch":
			return

		# Connecting with the next event

		arc_start_x = (indent_size * (current_indent_level + 1)) + (10 * _scale)
		arc_start_y = (pos_y + (8 * _scale))

		draw_arc(
			Vector2(arc_start_x, arc_start_y),
			arc_radius,
			deg2rad(start_angle),
			deg2rad(end_angle),
			arc_point_count,
			line_color,
			line_width - (1 * _scale),
			true
		)
