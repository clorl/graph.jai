#scope_file
initted := false;
sub: Subwindow_Info;

#scope_export

Alignment :: enum u8 {
		Begin	:: 1;
		Top		:: 1;
		Left	:: 1;

		End		:: 2;
		Bottom	:: 2;
		Right	:: 2;
		
		Center	:: 3;
}

Layout_Constraint :: enum u8 {
		None				:: 0;

		Begin				:: 1;
		Left				:: Begin;
		Top					:: Begin;

		End					:: 2;
		Right				:: End;
		Bottom				:: End;

		BeginAndEnd		:: 3;
		LeftAndRight	:: BeginAndEnd;
		TopAndBottom	:: BeginAndEnd;
		Fill				:: BeginAndEnd;
		
		Center				:: 4;
		Scale				:: 5; // Unused
}

Layout_Kind :: enum u8 {
		Free;
		Horizontal;
		Vertical;
		Grid; //@Todo
}

Sizing_Mode :: enum u8 {
		Fixed;
		// HugContents; To achieve this, first compute the child's layout and set sizing to fixed
		Fill;
		
}

Layout :: struct {
		x, y, width, height: float;
		#overlay (x) position: Vector2;
		#overlay (width) size: Vector2;
		#overlay (x) rect: Rect;
		#overlay (width) offset_x: float;
		#overlay (height) offset_y: float;

		min_width, min_height, max_width, max_height: float = -1;
		#overlay (min_width) min_size: Vector2;
		#overlay (max_width) max_size: Vector2;

		clip_overflow_content := true; //@Todo

		v_constraint: Layout_Constraint = .Top;
		h_constraint: Layout_Constraint = .Left;

		h_sizing: Sizing_Mode = .Fixed;
		v_sizing: Sizing_Mode = .Fixed;

		// Not used for .Fixed
		padding_left, padding_right, padding_top, padding_bottom: float = 0;

		// Used for Horizontal and Vertical layout
		// @Cleanup having everything stored for all layout types when it's not used is bad i think
		h_children_alignment: Alignment = .Left;
		v_children_alignment: Alignment = .Top;
		children_gap: float = 0;
		auto_children_gap := false;
		union kind: Layout_Kind = .Free {
				// Grid
				struct {
						rows: int;
						cols: int;
						auto_rows := false;
						children_gap_h: float = 0;
						children_gap_v: float = 0;
						auto_children_gap_h := false;
						auto_children_gap_v := false;
				}

		}
}

// get_offsets :: (layout: Layout) -> Offsets {
// 		assert(alignment % 2 == 0, "Please provide a single alignment");
// 		return 0;
// }

// set_offsets :: (layout: *Layout, of: Offsets) {
// }

// get_actual_size :: (layout: Layout) -> Vector2 {
// 		return .{};
// }


limit_size :: (it: *Layout) {
		if it.min_width >= 0 it.width = max(it.width, it.min_width);
		if it.max_width >= 0 it.width = min(it.width, it.max_width);
		if it.min_height >= 0 it.height = max(it.height, it.min_height);
		if it.max_height >= 0 it.height = min(it.height, it.max_height);
}

compute_layout :: (parent: Layout, children: .. *Layout) {
		assert(parent.kind != .Grid, "Not implemented");
		if parent.kind == .Free for children {
				if it.v_constraint == {
						case .Top;
						it.y += parent.y;
						case .Bottom;
						it.y += (parent.y + parent.height) - it.height - 2 * it.y;
						case .TopAndBottom;
						it.height = parent.height - it.offset_y - it.y;
						it.y += parent.y;
						case .Center;
						it.y += (parent.y + parent.height / 2.0) - it.height / 2.0;
				}

				if it.h_constraint == {
						case .Left;
						it.x += parent.x;
						case .Right;
						it.x += (parent.x + parent.width) - it.width - 2 * it.x;
						case .LeftAndRight;
						it.x += parent.x;
						it.width = parent.width - it.offset_x - it.x;
						case .Center;
						it.x += parent.x + parent.width / 2.0 - it.width / 2.0;
				}
				return;
		}

		// Apply padding
		parent_rect := parent.rect;
		 _,parent_rect = cut_top(parent_rect, parent.padding_top);
		 _,parent_rect = cut_bottom(parent_rect, parent.padding_bottom);
		 _,parent_rect = cut_right(parent_rect, parent.padding_right);
		_,parent_rect = cut_left(parent_rect, parent.padding_left);

		// Compute children total size
		fill_children := 0;
		cumul_size : float = 0;
		for children {
				limit_size(it);
				if parent.kind == .Horizontal && it.h_sizing == .Fill
						|| parent.kind == .Vertical && it.v_sizing == .Fill {
								fill_children += 1;
								continue;
						}

				if parent.kind == .Horizontal cumul_size += it.width;
				if parent.kind == .Vertical cumul_size += it.height;
		}

		// Compute gaps size
		gap_size :float = 0;
		if parent.children_gap > 0 && !parent.auto_children_gap {
				cumul_size += parent.children_gap * (children.count - 1);
				gap_size = parent.children_gap;
		}

	// Compute fill children size
		cumul_size = max(cumul_size, 0);
		remaining_size: float = (ifx parent.kind == .Horizontal parent_rect.w else parent_rect.h) - cumul_size;
		remaining_size = max(remaining_size, 0);
		fill_size: float = 0;
		if fill_children > 0 && remaining_size > 0 {
				fill_size = remaining_size / fill_children;
		}

		// Recalculate accounting for fill children with min/max width and height
		for children {
				if parent.kind == .Horizontal && it.h_sizing == .Fill {
						if fill_size <= 0 break;
						if it.max_width >= 0 && fill_size > it.max_width {
								remaining_size -= it.max_width;
								fill_children -= 1;
						} else if it.min_width >= 0 && fill_size < it.min_width {
								remaining_size -= it.min_width;
								fill_children -= 1;
						}
				}
				if parent.kind == .Vertical && it.v_sizing == .Fill {
						if fill_size <= 0 break;
						if it.max_height >= 0 && fill_size > it.max_height {
								remaining_size -= it.max_height;
								fill_children -= 1;
						} else if it.min_height >= 0 && fill_size < it.min_height {
								remaining_size -= it.min_height;
								fill_children -= 1;
						}
				}
		}
		remaining_size = max(remaining_size, 0);
		if fill_children > 0 && remaining_size > 0 {
				fill_size = remaining_size / fill_children;
		} else {
				fill_size = 0;
		}

		empty_space := remaining_size - fill_size * fill_children;

		if parent.auto_children_gap {
				gap_size = empty_space / (children.count - 1);
				empty_space = 0;
		}
		else if parent.kind == {
				case .Horizontal;
				if empty_space > 0 if parent.h_children_alignment == {
						case .Right; parent_rect.x += empty_space;
						case .Center; parent_rect.x += empty_space / 2.0;
				}

				case .Vertical;
				if empty_space > 0 if parent.v_children_alignment == {
						case .Bottom; parent_rect.y += empty_space;
						case .Center; parent_rect.y += empty_space / 2.0;
				}
		}


		available_space := parent_rect;
		// Place children 
		for children {
				it.x = available_space.x;
				it.y = available_space.y;
				gap : float = 0;
				
				if it_index > 0 gap = gap_size;

				if parent.kind == .Horizontal {
						if it.h_sizing == .Fill it.width = fill_size;
						if it.v_sizing == .Fill it.height = available_space.h;
						limit_size(it);

						if parent.v_children_alignment == {
								case .Top; it.y = available_space.y;
								case .Bottom; it.y = available_space.y + available_space.h - it.height;
								case .Center; it.y = (parent.y + parent.height / 2.0) - it.height / 2.0;
						}

						it.x += gap;
						_, available_space = cut_left(available_space, it.width + gap);
				}
				
				if parent.kind == .Vertical {
						if it.v_sizing == .Fill it.height = fill_size;
						if it.h_sizing== .Fill it.width = available_space.w;
						limit_size(it);

						if parent.h_children_alignment == {
								case .Left; it.x = available_space.x;
								case .Right; it.x = available_space.x + available_space.w - it.width;
								case .Center; it.x = (parent.x + parent.width / 2.0) - it.width / 2.0;
						}
						
						it.y += gap;
						available_space = cut_top(available_space, it.height + gap);
				}
		}
}

subwindow_layout := Layout.{};
v_scroll: float;
my_ui_init :: () {
		w :float = xx Graphics_Settings.win_width;
		h :float = xx Graphics_Settings.win_height;

		root_layout := Layout.{
				rect = get_rect(0, 0, w, h)
		};

		using sub;
		subwindow_layout = Layout.{
				rect = get_rect(20, 20, 200, 100),
				kind = .Free,
				padding_top = 24,
				v_children_alignment = .Center,
		};
		compute_layout(root_layout, *subwindow_layout);

		rect = subwindow_layout.rect;
		draw = draw_subwindow;
		title_text = "Subwindow";
		open = true;

		l := Layout.{};
}

draw_subwindow :: (state: *Subwindow_State, r: Rect, data: *void) {
		container_layout : Layout = .{
				kind = .Horizontal,
				v_constraint = .Fill,
				h_constraint = .Fill,
				x = 50,
				y = 50,
				width = 100,
				offset_y = 50,
		};

		compute_layout(subwindow_layout, *container_layout);
		{
				using container_layout;
				Simp.immediate_quad(x, y, x + width, y + height, Vector4.{1,1,1,1});
				Simp.immediate_flush();
		}
		

		btn_layout : Layout = .{
				x = 32,
				y= 32,
				width = 128,
				height = 32,
				min_height = 64,
		};
		btn_layout2 : Layout = .{
				x = 32,
				y= 32,
				width = 128,
				height = 32,
				min_width = 100,
				max_width = 300,
		};
		btn_layout3: Layout = .{
				x = 32,
				y= 32,
				width = 128,
				height = 32,
		};
		compute_layout(container_layout, *btn_layout, *btn_layout2, *btn_layout3);
		push_scissor(container_layout.rect);
		button(btn_layout.rect, "One");
		button(btn_layout2.rect, "Two");
		button(btn_layout3.rect, "Three");
		pop_scissor();
}

draw_ui :: () {
		if !initted {
				my_ui_init();
				initted = true;
		}

		w : float = xx Graphics_Settings.win_width;
		h : float = xx Graphics_Settings.win_height;

		root_layout := Layout.{
				rect = get_rect(0, 0, w, h),
		};

		subwindow_layout.rect = sub.rect;
		compute_layout(root_layout, *subwindow_layout);
		add_subwindow(*sub);

		draw_popups();
}

Stored_Layout :: struct {
		id: string;
		layout: Layout;
		children: [..] string;
}

load_layout_file :: (filename: string, path: string=".") -> bool, Table(string, Stored_Layout) {
		handler: Text_File_Handler;
		defer deinit(*handler);

		file_found, exe_path, exe_name := split_from_right(get_path_of_running_executable(), #char "/");
		if !file_found {
				log_error("Unable to find executable path\n");
				return false, .{};
		}

		complete_path := tprint("%/%/%", exe_path, path, filename);
		start_file(*handler, filename, filename, false);
		if handler.failed return false, .{};

		result: Stored_Layout;

		line, found := consume_next_line(*handler);
		if found {
		id, value := break_by_spaces(line);

				if !id {
						error(handler, tprint("Expected a space after identifier"));
				}

				if value == "{" {
						success, res := parse_layout_object(*handler, id);
						if success return true, res;
				}
		}

		return false, .{};
}

wip :: () {
		success, table := load_layout_file("example.layout");
		if !success {
				log_error("oop");
				return;
		}
		ok, root := table_find(*table, "root");
		if !ok return;
		for table {
				print("% > %\n", it_index, it.children);
		}
}

parse_layout_object :: (handler: *Text_File_Handler, id: string, depth := 0) -> bool, Table(string, Stored_Layout) {
		object_finished := false;
		result: Table(string, Stored_Layout);
		layout: Stored_Layout;
		data: Table(string, string);

		layout.id = id;

		while true {
				line, found := consume_next_line(handler);
				if !found break;
				
				if trim(line) == "}" {
						object_finished = true;
						break;
				}

				child_id, value := break_by_spaces(line);
				if !child_id {
						error(handler, "Expected space after id");
						break;
				}

				if value == "{" {
						success, res := parse_layout_object(handler, child_id, depth+1);
						if success for res {
								array_add(*layout.children, it_index);
								table_set(*result, it_index, it);
						}
				} else {
						table_set(*data, child_id, value);
				}
		}

		info := type_info(Layout);
		for info.members {
				success, str_value := table_find(*data, it.name);
				if !success continue;
				success = assign_field_from_string(*layout.layout, it.name, str_value);
				if !success log_error("Fail");
		}

		table_set(*result, id, layout);

		return object_finished, result;
}

assign_field_from_string :: (s: *$T, field_name: string, value: string) -> bool {
		info := cast(*Type_Info_Struct) type_info(T);
		field := get_field(info, field_name);

		if field.type.type == {
				case .UNTYPED_ENUM; #through;
				case .ENUM; {
						enum_info := cast(*Type_Info_Enum)field.type;
						if !enum_info return false;
						lower_name := to_lower_copy(value);
						found := -1;
						for enum_info.names {
								if to_lower_copy(it) == lower_name {
										found = it_index;
										break;
								}
						}
						if found <= -1 return false;
						enum_value := enum_info.values[found];
						memcpy(
								(cast(*u8) s) + field.offset_in_bytes,
										*enum_value,
								field.type.runtime_size
						);
				}
				case .INTEGER;
				int_value : float;
				success := set_value_from_string(int_value, *value);
				if success {
						memcpy(
								(cast(*u8) s) + field.offset_in_bytes,
								(cast(*u8) *int_value),
								field.type.runtime_size
						);
				}
				case .FLOAT;
				float_value : float;
				success := set_value_from_string(float_value, *value);
				if success {
						memcpy(
								(cast(*u8) s) + field.offset_in_bytes,
								(cast(*u8) *float_value),
								field.type.runtime_size
						);
				}
				case .BOOL;
				bool_value : float;
				success := set_value_from_string(bool_value, *value);
				if success {
						memcpy(
								(cast(*u8) s) + field.offset_in_bytes,
								(cast(*u8) *bool_value),
								field.type.runtime_size
						);
				}
				case .STRING;
				assert(false, "Todo");
				// memcpy(
				// 		(cast(*u8) s) + field.offset_in_bytes,
				// 		(cast(*u8) *bool_value),
				// 		field.type.runtime_size
				// );
		}
		return true;
}

#scope_file

#import "Unicode";
#import "System";
#import "String";
#import "Text_File_Handler";
#import "Basic";
#import "Math";
Simp :: #import "Simp";
Input :: #import "Input";
#import "GetRect_LeftHanded";
#import "Hash_Table";
#import "Random";
#import "Reflection";
