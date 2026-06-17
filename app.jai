Node :: struct {
		neighbors := 0;
		neighbors_idx: [7] s64;
		disp: Vector2;
}


other :: (e: Edge, idx: s64) -> s64 {
		assert(e[0] != e[1]);
		if e[0] == idx return e[1];
		return e[0];
}

Edge :: #type,isa [2] s64;

equals :: (a: Edge, b: Edge) -> bool {
		return (a[0] == b[0] && a[1] == b[1]) || (a[0] == b[1] && a[1] == b[0]);
}

operator == :: (a: Edge, b: Edge) -> bool {
		return inline equals(a, b);
}

Graph :: struct {
		positions: [..] Vector2;
		edges: [..] Edge;
		nodes: [..] Node;
};

graph: Graph;

add_unique_edge :: (using g: *Graph, a: s64, b: s64) -> bool, s64 {
		e := cast(Edge) .[a, b];
		idx := -1;
		for edges if equals(it,e) {
				idx = it_index;
				break;
		}
		if idx <= -1 {
				array_add(*edges, e);
				n := nodes[a].neighbors;
				nodes[a].neighbors_idx[n] = b;
				n = nodes[b].neighbors;
				nodes[b].neighbors_idx[n] = a;
				nodes[a].neighbors += 1;
				nodes[b].neighbors += 1;
		}

		return idx > -1, idx;
}

// returns true if new nodes have been created and returns them in an array
connect_node :: (using g: *Graph, node_idx: s64, neighbor_count := 5, create_at_least := 1) -> bool, [] s64 {
		for 0..positions.count - 1 {
				if node_idx == it continue;
				if nodes[it].neighbors >= neighbor_count continue;
				
				success, idx := add_unique_edge(g, node_idx, it);
				if nodes[node_idx].neighbors >= neighbor_count return false, .[];
				if nodes[node_idx].neighbors + create_at_least >= neighbor_count break;
		}

		remaining_neighbors := neighbor_count - nodes[node_idx].neighbors;
		new_nodes : [..] s64;

		while nodes[node_idx].neighbors < neighbor_count {
				nidx := add_node(g);
				array_add(*new_nodes, nidx);
				add_unique_edge(g, node_idx, nidx);
		}

		return true, new_nodes;
}

add_node :: (using g: *Graph) -> s64 {
		pos := Vector2.{
				random_get_within_range(-2, 2),
				random_get_within_range(-2, 2),
		};
		array_add(*positions, pos);
		array_add(*nodes, .{ neighbors = 0 });
		return positions.count - 1;
}

create_graph :: () -> Graph {
		using g: Graph;
		neighbor_count :: 6;

		idx := add_node(*g);
		created_new, new_nodes := connect_node(*g, idx, neighbor_count - 1);

		if created_new
		while positions.count < 30 {
				next_new_nodes: [..] s64;

				for new_nodes {
						ok, arr := connect_node(*g, it, cast(int) neighbor_count);
						if ok for arr array_add(*next_new_nodes, it);
				}

				if next_new_nodes.count <= 0 break;
				new_nodes = next_new_nodes;
		}

		for nodes {
				print("Node % has % neighbors: %\n", it_index, it.neighbors, it.neighbors_idx);
		}

		return g;
}

render_graph :: (using g: *Graph) {
		using Simp;
		for positions {
				if it_index == 0 continue;
				draw_circle(it, .1);
		}
		for edges {
				draw_line(positions[it[0]], positions[it[1]]);
		}
}

graph_apply_physics :: (g: *Graph, iterations := 1) {
		using g;
		frame_w, frame_l := 4;
		area := frame_w * frame_l;
		k := sqrt(cast(float)area / positions.count);

		fa :: (x: float, k: float) -> float { return (x*x)/k; };
		fr :: (x: float, k: float) -> float { return (k*k)/x; };
		for iter: 1..iterations {

				// --- Repulsive forces
				for v, vi: positions {
						nodes[vi].disp = .{};
						for u, ui: positions {
								if u == v continue;
								dir := v - u;
								nodes[vi].disp += normalize(dir) * fr(length(dir), k);

								//nodes[vi].disp = cast(float) nodes[vi].disp + normalize(dir) * cast(float) fr(length(dir), k);
						}
				}

				// --- Attractive forces
				for edges {
						dir := positions[it[1]] - positions[it[0]];
						v := *nodes[it[1]];
						u := *nodes[it[0]];
						v.disp -= normalize(dir) * fa(length(dir), k);
						u.disp += normalize(dir) * fa(length(dir), k);
				}

				// - Limit displacement
				for *v, vi: positions {
						vn := nodes[vi];
						positions[vi] = v.* + normalize(vn.disp) * vn.disp;
						v.x = clamp(v.x, -frame_w / 2.0, frame_w / 2.0);
						v.y = clamp(v.y, -frame_l / 2.0, frame_l / 2.0);
				}
		}
}

loop :: () -> bool {

		// --- INPUT
		for Input.events_this_frame {
				using it;
				if type == .QUIT || type == .KEYBOARD && key_pressed && key_code == .ESCAPE
				then return true;

          Gui.getrect_handle_event(it);

				if type == {
						// case .DRAG_AND_DROP_FILES;
						// for dropped_files free(it);
						// array_reset(*dropped_files);
						// for event.files array_add(*dropped_files, copy_string(it));
				}
		}

		// --- LOGIC


		// --- RENDERING
		{
				using Simp;
				set_shader_for_color();
				{ using Colors.background; clear_render_target(x, y, z, w); }

				new_ctx := context; push_context new_ctx {
						context.transform.basis = .{100, 0, 0,  -100};
						context.transform.origin = .{ Graphics_Settings.win_width / 2.0, Graphics_Settings.win_height / 2.0 };

						draw_grid(Transform2D.{}, Colors.foreground * .5, 1);
						draw_grid(Transform2D.{
								basis = { .5, 0,
									0, .5
								}
						}, Colors.foreground * .34, .5);
						draw_grid(scale(Transform2D.{}, 4), Colors.foreground * .8, 1);
						draw_arrow(.{0, 0}, .{1, 0}, Colors.red);
						draw_arrow(.{0, 0}, .{0, 1}, Colors.green);

						render_graph(*graph);
				}

				immediate_flush();
		}

		// --- UI
		{
				using Gui;
		}

		Simp.swap_buffers(window);

		return false;
}

// Initializes the window and stuff after creation
init :: (first_init := false) {
		// --- CONSTRUCT GRAPH

		{ // --- LOAD FONTS
				size := Graphics_Settings.win_height / 24;
				inter_tight := Simp.get_font_at_size("fonts/Inter_Tight/static", "InterTight-Medium.ttf", size);
				jetbrains_mono := Simp.get_font_at_size("fonts/JetBrains_Mono", "JetBrainsMono-VariableFont_wght.ttf", size);

				Fonts.mono = jetbrains_mono;
				Fonts.sans = inter_tight;
				Fonts.default = Fonts.sans;
		}

		if first_init {
				Gui.ui_init();
				graph = create_graph();
				graph_apply_physics(*graph, 100);
		}

		using Gui;
		proc := default_theme_procs[Default_Themes.Default];
		Ui_Settings.theme = proc();

		// Configure theme
		{
				using Ui_Settings.theme;
				background_color = Colors.background;
				background_color_bright = .{0.27, 0.28, 0.35, 1};
				text_color = Colors.foreground;
				title_bar_color = .{0.35, 0.36, 0.44, 1};
				title_bar_color_hilit = .{0.5, 0.52, 0.61, 1};
				font = Fonts.default;
				{
						using button_theme;
						font = Fonts.default;
				}
		}

		set_default_theme(Ui_Settings.theme);
}

#scope_file

#import "Basic";
#import "Math";
Simp :: #import "Simp";
Gui :: #import "GetRect_LeftHanded";
Input :: #import "Input";
#import "Hash_Table";
#import "Random";

PI :: 3.1415;
TAU :: PI * 2.0;
