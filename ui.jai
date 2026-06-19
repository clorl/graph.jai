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
		Grid; //@Todo
}

Sizing_Mode :: enum {
		Fixed;
		HugContents; //@Todo
		Fill;
}

Layout :: struct {
		x, y, width, height: float;
		#overlay (x) position: Vector2;
		#overlay (width) size: Vector2;
		#overlay (x) rect: Rect;

		min_width, min_height, max_width, max_height: float = -1;
		#overlay (min_width) min_size: Vector2;
		#overlay (max_width) max_size: Vector2;

		clip_overflow_contents := false;
		//@Todo aspect ratio

		v_constraint: Layout_Constraint = .Top;
		h_constraint: Layout_Constraint = .Left;

		h_sizing: Sizing_Mode = .Fixed;
		v_sizing: Sizing_Mode = .Fixed;
		
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

compute_layout :: (parent: Layout, layout: *Layout) {
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
}

limit_size :: (it: *Layout) {
		if it.min_width >= 0 it.width = max(it.width, it.min_width);
		if it.max_width >= 0 it.width = min(it.width, it.max_width);
		if it.min_height >= 0 it.height = max(it.height, it.min_height);
		if it.max_height >= 0 it.height = min(it.height, it.max_height);
}

compute_layout :: (parent: Layout, children: .. *Layout) {
		if parent.kind == .Free for children compute_layout(parent, it);

		_,remaining_rect := cut_top(parent.rect, parent.padding_top);
		_,remaining_rect = cut_bottom(remaining_rect, parent.padding_bottom);
		_,remaining_rect = cut_right(remaining_rect, parent.padding_right);
		_,remaining_rect = cut_left(remaining_rect, parent.padding_left);

		for children {
				it.x = remaining_rect.x;
				it.y = remaining_rect.y;

				if parent.kind == .Horizontal {
						if it.v_sizing == .Fill it.height = remaining_rect.h;
						limit_size(it);

						_, remaining_rect = cut_left(remaining_rect, it.width);
				}
				
				if parent.kind == .Vertical {
						if it.h_sizing== .Fill it.width = remaining_rect.w;
						limit_size(it);
						_, remaining_rect = cut_top(remaining_rect, it.height);
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
				kind = .Vertical,
				padding_top = 24
		};
		compute_layout(root_layout, *subwindow_layout);

		rect = subwindow_layout.rect;
		draw = draw_subwindow;
		title_text = "Subwindow";
		open = true;

		l := Layout.{};
		print("%\n", l.kind);
}

draw_subwindow :: (state: *Subwindow_State, r: Rect, data: *void) {
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
				h_sizing = .Fill,
				min_width = 100,
				max_width = 300,
		};
		btn_layout3: Layout = .{
				x = 32,
				y= 32,
				width = 128,
				height = 32,
		};
		compute_layout(subwindow_layout, *btn_layout, *btn_layout2, *btn_layout3);
		button(btn_layout.rect, "One");
		button(btn_layout2.rect, "Two");
		button(btn_layout3.rect, "Three");
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

		subwindow_layout.rect = sub.rect;
		compute_layout(root_layout, *subwindow_layout);
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
