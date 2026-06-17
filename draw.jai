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

draw_arrow :: (from: Vector2, to: Vector2, color := WHITE, thickness := 2.0, head_size : float = .1) {
		t := context.transform;
		head_size = clamp(head_size, 0, 1.0);
		dir := to - from;
		new_dir := dir * (1 - head_size);
		line_end := from + new_dir;

		draw_line(from, line_end, color, thickness);

		normal := normalize(.{new_dir.y, -new_dir.x});
		head_size_transformed := distance(t * to, t * line_end) / 2.0;

		p0 := t * to;
		p1 := t * line_end + normal * head_size_transformed;
		p2 := t * line_end - normal * head_size_transformed;
		immediate_triangle(xyz(p0, 0), xyz(p1, 0), xyz(p2, 0), color, color, color);
}

draw_grid :: (t: Transform2D, color := WHITE, thickness := 2.0, subdivide := false, subdivision_count := 1, subdivision_color := NOCOLOR, subdivision_thickness := -1.0) {
		sub_color := subdivision_color;
		if subdivide {
				if subdivision_color == NOCOLOR sub_color = color * .7;
				if subdivision_thickness <= 0 subdivision_thickness = 0.5 * thickness;
		}

		using Graphics_Settings;
		tinv := inverse(t);
		new_t := context.transform * t;
		new_t.origin.x = fmod_cycling(new_t.origin.x, xx win_width);
		new_t.origin.y = fmod_cycling(new_t.origin.y, xx win_height);

		screen_start := tinv * t.origin;
		screen_end := screen_start + Vector2.{xx win_width, xx win_height};
		draw_arrow(screen_start, t.origin);
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
				-t.origin,
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
