draw_line :: (from: Vector2, to: Vector2, color := WHITE, thickness := 2.0) {
		t := context.transform;

		dir := t * to - t * from;
		normal := normalize(.{dir.y, -dir.x});
		ht := thickness / 2.0;

		immediate_quad(
				t * from + normal * ht,
				t * from - normal * ht,
				t * to - normal * ht,
				t * to + normal * ht,
				color
		);
}

draw_arrow :: (from: Vector2, to: Vector2, color := WHITE, thickness := 2.0, head_size: int = 16) {
		t := context.transform;
		dir := t * to - t * from;
		new_length := 1.0 - (head_size - length(dir));
		new_dir := normalize(dir) * new_length;
		line_end := t * from + new_dir;
		normal := normalize(.{new_dir.y, -new_dir.x});
		ht := thickness / 2.0;

		immediate_quad(
				t * from + normal * ht,
				t * from - normal * ht,
				line_end - normal * ht,
				line_end + normal * ht,
				color
		);

		hs := head_size / 3.0;
		p0 := t * to;
		p1 := line_end + normal * hs;
		p2 := line_end - normal * hs;
		immediate_triangle(xyz(p0, 0), xyz(p1, 0), xyz(p2, 0), color, color, color);
}

draw_grid :: (t: Transform2D, color := WHITE, thickness := 2.0, subdivide := false, subdivision_count := 1, subdivision_color := NOCOLOR, subdivision_thickness := -1.0) {
		sub_color := subdivision_color;
		if subdivide {
				if subdivision_color == NOCOLOR sub_color = color * .7;
				if subdivision_thickness <= 0 subdivision_thickness = 0.5 * thickness;
		}

		using Graphics_Settings;

		inv := inverse(context.transform);
		screen_start := inv * Vector2.{0, 0};
		screen_end := inv * Vector2.{ xx win_width, xx win_height };

		w := abs(screen_end.x - screen_start.x);
		h := abs(screen_end.y - screen_start.y);

		hlines: int = xx (w / length(t2d_right(t)));
		vlines: int = xx (h / length(t2d_up(t)));

		for 0..vlines-1 {
				x : float = (w / vlines) * it;
				sx := min(screen_start.x, screen_end.x);
				sy := min(screen_start.y, screen_end.y);
				ey := max(screen_start.y, screen_end.y);
				draw_line(
						.{sx + x, sy},
						.{sx + x, sy},
				);
				//print("%\n", Vector2.{x, screen_start.y});
		}

		for 0..abs(hlines)-1 {
				y : float = (h / hlines) * it;
				draw_line(
						.{screen_start.x, screen_start.y + y},
						.{screen_end.x, screen_start.y + y},
				);
		}
		//print("% % \n", hlines, vlines);
}

draw_polygon :: (pos: Vector2, diameter := 1.0, sides := 4, color := WHITE, filled := true, angle_offset: float = 0, outline_thickness := 2.0) {
		assert(sides >= 3);
		t := context.transform;
		angle: float = xx (TAU / sides);
		//radius := diameter / (2 * sin(angle)); // Calculate the radius for a given desired edge length
		radius := diameter / 2.0;
		start_angle: float = angle_offset - angle / 2.0;

		right := Vector2.{radius, 0};
		v0 := pos + rotate(right, start_angle);

		for i: 1..sides-1 {
				vcur := pos + rotate(right, start_angle + angle * i);
				vnex := pos + rotate(right, start_angle + angle * ((i+1) % sides));

				if filled {
						immediate_vertex(xyz(t * v0, 0), color);
						immediate_vertex(xyz(t * vcur, 0), color);
						immediate_vertex(xyz(t * vnex, 0), color);
				} else {
						if i == 1 draw_line(v0, vcur, color, outline_thickness);
						draw_line(vcur, vnex, color, outline_thickness);
				}
		}
}

draw_circle :: (pos: Vector2, diameter := 1.0, color := WHITE, filled := true, quality := 1.0) {
		q := max(quality, 0);
		sides := cast(int) floor(100 * q);
		inline draw_polygon(pos, diameter, sides, color, filled);
}

Transform2D :: struct {
		basis := Matrix2_Identity;
		origin := Vector2.{0, 0};
}

inverse :: inline (t: Transform2D) -> Transform2D {
		using t.basis;
		determinant := _11 * _22 - _12 * _21;
		inverse := (1.0/determinant) * Matrix2.{
				_22, -_12,
				-_21, _11
		};

		return .{
				inverse,
				inverse * -t.origin,
		};
}

t2d_right :: inline (t: Transform2D) -> Vector2 {
		return .{t.basis.coef[0][0], t.basis.coef[0][1]};
}

t2d_up :: inline (t: Transform2D) -> Vector2 {
		return .{t.basis.coef[1][0], t.basis.coef[1][1]};
}

operator * :: (t: Transform2D, v: Vector2) -> Vector2 {
		return (t.basis * v) + t.origin;
}

operator * :: (t1: Transform2D, t2: Transform2D) -> Transform2D {
		return .{
				t1.basis * t2.basis,
				t1.origin + t2.origin
		};
}

#add_context transform: Transform2D;

#scope_file

WHITE :: Vector4.{1,1,1,1};
NOCOLOR :: Vector4.{0, 0, 0, 0};
PI :: 3.1415926535;
TAU :: 2.0 * PI;

#import "Basic";
#import "Simp";
#import "Math";
#import "Sloppy_Math";
