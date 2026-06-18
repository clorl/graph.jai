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
		Left				:: Begin;
		Top					:: Begin;

		End					:: 2;
		Right				:: End;
		Bottom				:: End;

		BeginAndEnd		:: 3;
		LeftAndRight	:: BeginAndEnd;
		TopAndBottom	:: BeginAndEnd;
		
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
		if parent.kind == .Free {
				if layout.v_constraint == {
						case .Top;
						layout.y += parent.y;
						case .Bottom;
						layout.y += (parent.y + parent.height) - layout.height - 2 * layout.y;
						case .TopAndBottom;
						layout.y += parent.y;
						layout.height = parent.height - layout.height;
						case .Center;
						layout.y += (parent.y + parent.height / 2.0) - layout.height / 2.0;
				}

				if layout.h_constraint == {
						case .Left;
						layout.x += parent.x;
						case .Right;
						layout.x += (parent.x + parent.width) - layout.width - 2 * layout.x;
						case .LeftAndRight;
						layout.x += parent.x;
						layout.width = parent.width - layout.width;
						case .Center;
						layout.x += parent.x + parent.width / 2.0 - layout.width / 2.0;
				}
		}
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
		subwindow_layout = Layout.{ rect = get_rect(20, 20, 200, 100) };
		compute_layout(*subwindow_layout, root_layout, root_layout.rect);

		rect = subwindow_layout.rect;
		draw = draw_subwindow;
		title_text = "Subwindow";
		open = true;

		l := Layout.{};
		print("%\n", l.kind);
}

draw_subwindow :: (state: *Subwindow_State, r: Rect, data: *void) {

		id := 0;
		for h: 1..4 for v: 1..4 {
				if h == 3 || v == 3 continue;
				id += 1;
				hstrings := string.["", "Left", "Right", "Left+Right", "Center"];
				vstrings := string.["", "Top", "Bottom", "Top+Bottom", "Center"];

				btn_layout : Layout = {
						x = 32,
						y= 32,
						width = 128,
						height = 32,
						h_constraint = cast(Layout_Constraint) h,
						v_constraint = cast(Layout_Constraint) v,
				};
				compute_layout(*btn_layout, subwindow_layout, subwindow_layout.rect);
				button(btn_layout.rect, tprint("% %", hstrings[h], vstrings[v]), identifier=id);
		}
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
