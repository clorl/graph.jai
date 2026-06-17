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

draw_grid :: (t: Transform2D, color := WHITE, thickness := 2.0) {
        using Graphics_Settings;

        combined_transform := context.transform * t;
        inv_combined := inverse(combined_transform);

        c0 := inv_combined * Vector2.{0, 0};
        c1 := inv_combined * Vector2.{xx win_width, 0};
        c2 := inv_combined * Vector2.{0, xx win_height};
        c3 := inv_combined * Vector2.{xx win_width, xx win_height};

        min_x := min(min(c0.x, c1.x), min(c2.x, c3.x));
        max_x := max(max(c0.x, c1.x), max(c2.x, c3.x));
        min_y := min(min(c0.y, c1.y), min(c2.y, c3.y));
        max_y := max(max(c0.y, c1.y), max(c2.y, c3.y));

        start_x := cast(int) floor(min_x);
        end_x := cast(int) ceil(max_x);
        start_y := cast(int) floor(min_y);
        end_y := cast(int) ceil(max_y);

        for start_x..end_x {
                p0_grid := Vector2.{xx it, min_y};
                p1_grid := Vector2.{xx it, max_y};
                
                p0 := t * p0_grid;
                p1 := t * p1_grid;
                
                draw_line(p0, p1, color, thickness);
        }
        
        for start_y..end_y {
                p2_grid := Vector2.{min_x, xx it};
                p3_grid := Vector2.{max_x, xx it};
                
                p2 := t * p2_grid;
                p3 := t * p3_grid;
                
                draw_line(p2, p3, color, thickness);
        }
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

scale :: inline (t: Transform2D, s: float) -> Transform2D {
		r := t2d_right(t) * s;
		u := t2d_up(t) * s;

		return .{
				{
						r.x, u.x,
						r.y, u.y
				},
				t.origin
		};
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
