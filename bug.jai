Edge :: #type,isa [2] s64;

edges: [..] Edge;

equals :: (a: Edge, b: Edge) -> bool {
		return (a[0] == b[0] && a[1] == b[1]) || (a[0] == b[1] && a[1] == b[0]);
}

operator == :: (a: Edge, b: Edge) -> bool {
		return inline equals(a, b);
}

main :: () {
		for i: 1..10 for j: 1..10 array_add(*edges, cast(Edge).[i, j]);
		e := cast(Edge).[2, 1];

		print("\nUsing == operator\n");
		for edges if it == e print("Found a match: %\n", it);

		print("\nUsing equals function\n");
		for edges if equals(it,e) print("Found a match: %\n", it);
}

#import "Basic";
