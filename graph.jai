Node :: struct {
		position: Vector2;
		velocity: Vector2;
		neighbors := 0;
		neighbors_idx: [7] s64;
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
		for 0..nodes.count - 1 {
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
		array_add(*nodes, .{
				position = pos,
				neighbors = 0
		});
		return nodes.count - 1;
}

create_graph :: (neighbor_count: int) -> Graph {
		using g: Graph;

		idx := add_node(*g);
		created_new, new_nodes := connect_node(*g, idx, neighbor_count - 1);

		if created_new
		while nodes.count < 30 {
				next_new_nodes: [..] s64;

				for new_nodes {
						ok, arr := connect_node(*g, it, cast(int) neighbor_count);
						if ok for arr array_add(*next_new_nodes, it);
				}

				if next_new_nodes.count <= 0 break;
				new_nodes = next_new_nodes;
		}

		return g;
}

render_graph :: (using g: *Graph) {
		using Simp;
		for nodes {
				if it_index == 0 continue;
				draw_circle(it.position, .1);
		}
		for edges {
				draw_line(nodes[it[0]].position, nodes[it[1]].position);
		}
}

graph_apply_physics :: (using g: *Graph, iterations := 1, ideal_node_distance := .5, drag := .5, attraction_factor := .1) {
		for 1..iterations {
				// --- Repulsion (Coulombs force)
				for *a: nodes for *b: nodes {
						if a == b continue;
						atob := normalize(b.position - a.position);
						btoa := normalize(a.position - b.position);

						dist := distance_squared(a.position, b.position);
						force := attraction_factor / (dist);
						a.velocity += btoa * force;
						b.velocity += atob * force;
				}

				// --- Attraction
				for edges {
						a := *nodes[it[0]];
						b := *nodes[it[1]];
						dist : float = distance(a.position, b.position);
						//if dist <= ideal_node_distance_squared continue;

						atob := normalize(b.position - a.position);
						btoa := normalize(a.position - b.position);

						b.velocity += atob * (ideal_node_distance - dist);
						a.velocity += btoa * (ideal_node_distance - dist);
				}

				max_speed :: .5;

				// --- Apply forces
				for *nodes {
						//it.velocity *= 1 - drag; // Drag
						if length(it.velocity) > max_speed it.velocity = normalize(it.velocity) * max_speed;
						it.position += it.velocity;
				}
		}
}

#scope_file

#import "Basic";
#import "Math";
Simp :: #import "Simp";
