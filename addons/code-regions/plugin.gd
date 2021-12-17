tool
extends EditorPlugin


# ==== user area ============================
# requires reloading the plugin and scripts

export var region_color: = Color.mediumpurple
export var region_start_keyword: = "region"
export var region_end_keyword: = "region_end"

# ===========================================


var recently_found_region_end: = 0
var hide_region_menu_item_id: = 123321

func _enter_tree():
	var scr_ed = get_editor_interface().get_script_editor()

	if not scr_ed.is_connected("editor_script_changed", self, "on_script_changed"):
		scr_ed.connect("editor_script_changed", self, "on_script_changed")

	on_script_changed(null)

	return

	#region Hello Region!

	x()
	x()
	x()
	#region_end

	if false:
		#region test
		1
		2
		3
		4
		#region_end




func on_script_changed(_scr):
	yield(get_tree(),"idle_frame")

	recently_found_region_end = 0
	
	var scr_ed: = get_editor_interface().get_script_editor()
	var scr = scr_ed.get_current_script() as GDScript
	if not scr: return # only gds supported
	

	var cur_text_ed:TextEdit = get_current_text_ed(scr_ed)
	if not cur_text_ed: return

	if not cur_text_ed.has_meta("has_region_color"):
		cur_text_ed.set_meta("has_region_color", true)
		cur_text_ed.add_color_region("	#region", "", region_color, true)

	var script_text_ed = cur_text_ed.get_parent().get_parent().get_parent()

	var context_menu:PopupMenu = find_child_by_type(script_text_ed, PopupMenu)
	if not context_menu.is_connected("about_to_show", self, "on_context_menu_show"):
		context_menu.connect("about_to_show", self, "on_context_menu_show", [cur_text_ed, context_menu])
		context_menu.connect("id_pressed", self, "on_menu_id_pressed", [cur_text_ed, context_menu])


# can be done using regex
# returns 0 if region end not found
# region_max_line_count arg could be added later
func find_region_end(textedit:TextEdit, start_line:int, indent_chars_count:int, indent_is_tab:bool)->int:
	for i in range(start_line,textedit.get_line_count()):
		var line_text = textedit.get_line(i)
		var line_len = line_text.length()
		if line_len< 9: continue
		var stripped:String = line_text.lstrip("	") if indent_is_tab else line_text.lstrip(" ")
		if !stripped.begins_with("#"+region_end_keyword): continue
		var current_line_indent_chars_count:int = line_len-stripped.length()
		if !current_line_indent_chars_count==indent_chars_count: continue
		return i
	return 0


func on_menu_id_pressed(id:int, textedit:TextEdit, menu:PopupMenu):
	if not recently_found_region_end: return
	match id:
		hide_region_menu_item_id:
			for i in range(textedit.cursor_get_line()+1, recently_found_region_end+1):
				textedit.set_line_as_hidden(i, true)


func on_context_menu_show(textedit:TextEdit, menu:PopupMenu):
	var line:int = textedit.cursor_get_line()
	var line_text:String = textedit.get_line(line)
	var indent_is_tab = '	#'+region_start_keyword in line_text
	
	if not indent_is_tab and not ' #'+region_start_keyword in line_text: return

	var line_len: = line_text.length()
	var stripped:String = line_text.lstrip("	") if indent_is_tab else line_text.lstrip(" ")
	
	if !stripped.begins_with("#"+region_start_keyword): return

	var indent_chars_count:int = line_len-stripped.length()

	var region_end:int = find_region_end(textedit, line+1, indent_chars_count, indent_is_tab)
	recently_found_region_end = region_end
	if not region_end:	return
	
	
	menu.add_separator("")
	menu.add_item("Hide region", hide_region_menu_item_id)
	menu.rect_size = Vector2.ZERO # force update menu (is it needed?)
	

func _exit_tree():
	pass

func x():
	pass


# ==================== Utils ========================
# Todo: refactor

static func get_script_tab_container(scr_ed:ScriptEditor)->TabContainer:
	return find_node_by_class_path(scr_ed, ['VBoxContainer', 'HSplitContainer', 'TabContainer']) as TabContainer

static func get_script_text_editor(scr_ed:ScriptEditor, idx:int)->Container:
	var tab_cont = get_script_tab_container(scr_ed)
	return tab_cont.get_child(idx)

static func get_code_editor(scr_ed:ScriptEditor, idx:int)->Container:
	var scr_text_ed = get_script_text_editor(scr_ed, idx)
	return find_node_by_class_path(scr_text_ed, ['VSplitContainer', 'CodeTextEditor']) as Container

# some items can be null, this means not previously opened?
static func get_code_editors(scr_ed:ScriptEditor)->Array:
	var scr_tab_cont:TabContainer = get_script_tab_container(scr_ed)
	var result =[]
	#var code_ed_temp
	for s in scr_tab_cont.get_children():
		if ! s.get_child_count():
			result.push_back(null)
		else:
			result.push_back(find_node_by_class_path(s, ['VSplitContainer', 'CodeTextEditor']))
	return result

static func get_text_edit(scr_ed:ScriptEditor, idx:int)->TextEdit:
	var code_ed = get_code_editor(scr_ed, idx)
	return find_node_by_class_path(code_ed, ['TextEdit']) as TextEdit

static func get_current_script_idx(scr_ed:ScriptEditor)->int:
	var current = scr_ed.get_current_script()
	var opened = scr_ed.get_open_scripts()
	return opened.find(current)

static func get_current_text_ed(scr_ed:ScriptEditor)->TextEdit:
	var idx = get_current_script_idx(scr_ed)
	return get_text_edit(scr_ed, idx)






static func find_child_by_type(node:Node, type):
	for child in node.get_children():
		if child is type:
			return child


static func find_node_by_class_path(node:Node, class_path:Array, inverted:= true)->Node:
	var res:Node

	var stack = []
	var depths = []

	var first = class_path[0]
	
	var children = node.get_children()
	if not inverted:
		children.invert()

	for c in children:
		if c.get_class() == first:
			stack.push_back(c)
			depths.push_back(0)

	if not stack: return res
	
	var max_ = class_path.size()-1

	while stack:
		var d = depths.pop_back()
		var n = stack.pop_back()

		if d>max_:
			continue
		if n.get_class() == class_path[d]:
			if d == max_:
				res = n
				return res

			var children_ = n.get_children()
			if not inverted:
				children_.invert()
			for c in children_:
				stack.push_back(c)
				depths.push_back(d+1)

	return res
