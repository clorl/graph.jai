#scope_file
initted := false;
sub: Subwindow_Info;

#scope_export

Alignment :: enum_flags {
		Top		:: 1;
		Right	:: 2;
		Bottom	:: 4;
		Left	:: 8;
		Center	:: 16;
}

Layout_Constraint :: enum {
		None				:: 0;

		Begin				:: 1;
		Left				:: 1;
		Top					:: 1;

		End					:: 2;
		Right				:: 2;
		Bottom				:: 2;

		BeginAndEnd		:: 3;
		LeftAndRight	:: 3;
		TopAndBottom	:: 3;
		
		Center				:: 4;
		Scale				:: 5;
}

Layout_Kind :: enum {
		Free;
		Horizontal;
		Vertical;
		Grid;
}

Sizing_Mode :: enum {
		Fixed;
		HugContents;
		Fill;
}

Size_Limits :: enum_flags {
		None;
		MinWidth;
		MinHeight;
		MaxWidth;
		MaxHeight;
}

Layout :: struct {
		x, y, width, height: float;
		#overlay (x) position: Vector2;
		#overlay (width) size: Vector2;
		#overlay (x) rect: Rect;

		min_width, min_height, max_width, max_height: float = -1;
		#overlay (min_width) min_size: Vector2;
		#overlay (max_width) max_size: Vector2;

		// apply min/max width/height or not
		size_limits: Size_Limits = .None;

		clip_overflow_contents := false;
		//@Todo aspect ratio

		v_constraint: Layout_Constraint = .Top;
		h_constraint: Layout_Constraint = .Left;
		
		union kind: Layout_Kind = .Free {

				// Horizontal and Vertical
				struct {
						children_alignment: Alignment = .Top | .Left;
						children_gap: float = 0;
						auto_children_gap := false;
				}

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
						padding_left, padding_right, padding_top, padding_bottom: float;
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

// Returns is_visible
compute_layout :: (layout: *Layout, parent: Layout, parent_available_space: Rect) -> bool {
		//if layout.rect.w <= 0 || layout.rect.h <= 0 return false, .{};
		//if parent_layout.clip_overflow_contents && !point_within(result.position, parent.rect) return false, .{};
		
		layout.position += parent.position;
		return true;
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
		layout := Layout.{ rect = get_rect(20, 20, 200, 100) };
		compute_layout(*layout, root_layout, root_layout.rect);

		rect = layout.rect;
		draw = draw_subwindow;
		title_text = "Subwindow";
		open = true;

		l := Layout.{};
		print("%\n", l.kind);
}

draw_subwindow :: (state: *Subwindow_State, r: Rect, data: *void) {

		btn_layout := Layout.{
				rect = get_rect(10, 30, 128, 32)
		};
		compute_layout(*btn_layout, subwindow_layout, subwindow_layout.rect);
		button(btn_layout.rect, "Hello");
}

draw_ui :: () {
		if !initted {
				my_ui_init();
				initted = true;
		}

		w : float = xx Graphics_Settings.win_width;
		h : float = xx Graphics_Settings.win_height;

		root_layout := Layout.{
				rect = get_rect(0, 0, w, h)
		};

		subwindow_layout = Layout.{ rect = sub.rect };
		compute_layout(*subwindow_layout, root_layout, root_layout.rect);
		add_subwindow(*sub);

		// btn_layout := Layout.{ rect = get_rect(400, 400, 80, 20) };
		// compute_layout(*btn_layout, subwindow_layout, subwindow_layout.rect);
		// button(btn_layout.rect, "Hello");

		draw_popups();
}

#scope_file

#import "Basic";
#import "Math";
Simp :: #import "Simp";
Input :: #import "Input";
#import "GetRect_LeftHanded";
#import "Hash_Table";
#import "Random";
