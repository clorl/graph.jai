#load "solitaire.jai";
#load "graph.jai";

graph_init :: (neighbors := 3) {
		// graph = create_graph(3);
		// graph_apply_physics(*graph, 100);
}


main :: () {
		using Simp;

		window := init_window();
		set_target_fps(60);

		assert(texture_load_from_file(*cards_atlas, "./textures/kenney/Spritesheets/playingCards.png"));
		assert(texture_load_from_file(*backs_atlas, "textures/kenney/Spritesheets/playingCardBacks.png"));



		while event_loop(window) {
				clear_render_target(rgb(0x13753c));

				{
						src: Rect = .{ position = CARDS_SPRITE_POSITIONS[10], size = CARDS_SPRITE_SIZE };

						t: Transform2D = .{
								position = .{xx cos(seconds_since_init()) * 100., xx sin(seconds_since_init()) * 100.},
								scale = .{0.5, 0.5},
						};
						draw_texture(*cards_atlas, src, transform = t);
				}

				swap_buffers(window);
				//log("FPS: %\n", 1.0/context.delta_time);
		}
}

backs_atlas: Simp.Texture;
cards_atlas: Simp.Texture;
CARDS_SPRITE_SIZE :: Vector2.{140, 190};
CARDS_SPRITE_POSITIONS :: Vector2.[
	.{ 0, 570},
	.{ 140, 380},
	.{ 140, 190},
	.{ 140, 0},
	.{ 0, 1710},
	.{ 0, 1520},
	.{ 0, 1330},
	.{ 0, 1140},
	.{ 0, 950},
	.{ 0, 760},
	.{ 0, 380},
	.{ 0, 0},
	.{ 0, 190},
	.{ 560, 570},
	.{ 280, 1140},
	.{ 700, 190},
	.{ 700, 0},
	.{ 560, 1710},
	.{ 560, 1520},
	.{ 560, 1330},
	.{ 560, 1140},
	.{ 560, 950},
	.{ 560, 760},
	.{ 560, 380},
	.{ 560, 0},
	.{ 560, 190},
	.{ 420, 0},
	.{ 420, 1710},
	.{ 420, 1520},
	.{ 420, 1330},
	.{ 420, 1140},
	.{ 420, 950},
	.{ 420, 760},
	.{ 420, 570},
	.{ 420, 380},
	.{ 420, 190},
	.{ 280, 1710},
	.{ 280, 1330},
	.{ 280, 1520},
	.{ 140, 1330},
	.{ 700, 380},
	.{ 280, 950},
	.{ 280, 760},
	.{ 280, 570},
	.{ 280, 380},
	.{ 280, 190},
	.{ 280, 0},
	.{ 140, 1710},
	.{ 140, 1520},
	.{ 140, 1140},
	.{ 140, 760},
	.{ 140, 950}
];

#import "Basic";
Input :: #import "Input";
Simp :: #import "Graphics";
#import "Math";
#import "Window_Creation";
