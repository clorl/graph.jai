#load "solitaire.jai";
#load "graph.jai";

graph_init :: (neighbors := 3) {
		// graph = create_graph(3);
		// graph_apply_physics(*graph, 100);
}

input_state: Input_State;
drag_state: struct {
		is_dragging := false;
		start_pos: Vector2;
		mouse_offset: Vector2;
		card: Card;
};


main :: () {
		using Simp;

		window := init_window();
		set_target_fps(60);

		assert(texture_load_from_file(*cards_atlas, "./textures/kenney/Spritesheets/playingCards.png"));
		assert(texture_load_from_file(*backs_atlas, "textures/kenney/Spritesheets/playingCardBacks.png"));

		game_state := make_game_state();
		{
				using game_state;
				draw.data += 3;
				draw.count -= 3;
				discard.data = deck.data;
				discard.count = 3;
		}
		transform := Transform2D.{
				scale = .{ .5, .5 }
		};
		card_size := CARDS_SPRITE_SIZE * transform.scale;

		while event_loop(window) {
				update_input_state(*input_state, Input.events_this_frame);

				clear_render_target(rgb(0x13753c));
				mouse_x, mouse_y, success := get_mouse_pointer_position(window, false);

				{
						using game_state;

						margin := 24;
						w, h := get_render_dimensions(window);
						last_x := w - margin;
						spacing := (last_x - margin) / (1.0 * PLAY_PILES_COUNT);

						deck_pos := Vector2.{xx margin, xx margin};
						if draw.count > 0 {
								offset := 4;
								for < 0..5 {
										p := deck_pos;
										p.y += offset * it;
										draw_card(Card.{ value=1 }, p, transform.scale.x);
								}
						}

						if discard.count > 0 {
								pos := deck_pos;
								pos.x += 90;
								for discard.count - 4..discard.count - 1 {
										if it < 0 continue;
										card := discard[it];
										card.face_up = true;
										draw_card(card, pos, transform.scale.x);
										pos.x += 32;
								}
						}

						for play_piles {
								pile_pos := Vector2.{xx (margin + spacing * it_index), xx (margin + 150)};
								for it {
										card_pos := Vector2.{pile_pos.x, xx (pile_pos.y + margin * it_index)};
										tint := WHITE;

										card_rect := Rect.{ position = card_pos, size = CARDS_SPRITE_SIZE * transform.scale.x };

										if it.face_up && GetRect.is_inside(xx mouse_x, xx mouse_y, card_rect) {
												tint = .{.9, .9, .9, 1.0};

												if input_state.mouse_left.just_pressed {
														tint = .{.8,.8,.8, 1.0};
														drag_state.is_dragging = true;
														drag_state.start_pos = card_pos;
														drag_state.mouse_offset = card_pos - Vector2.{xx mouse_x, xx mouse_y};
														drag_state.card = it;
												}
										}

										if input_state.mouse_left.just_released {
												drag_state = .{};
										}

										if drag_state.is_dragging && drag_state.card == it {
												tint = .{.9, .9, .9, 1.0};
												card_pos = drag_state.mouse_offset + Vector2.{xx mouse_x, xx mouse_y};
										}


										draw_card(it, card_pos, transform.scale.x, tint = tint);
								}
						}

				}
				//mouse_x, mouse_y, success := get_mouse_pointer_position(window, false);
				swap_buffers(window);
				reset_temporary_storage();
		}
}

Rect :: Simp.Rect;

on_hover :: (using c: Card, r: Rect) {
}

on_mouse_down :: (using c: Card, r: Rect) {
}

on_mouse_up :: (using c: Card, r: Rect) {
}

draw_card :: (using c: Card, position: Vector2, scale := 1.0, tint := Simp.WHITE) {
		if value == 0 return;
		using Simp;
		src: Rect = .{ size = CARDS_SPRITE_SIZE };
		atlas: *Texture = *backs_atlas;

		if face_up {
				sprite_index := 13 * cast(u8) suit + value - 1;
				if sprite_index < 0 return;
				src.position = CARDS_SPRITE_POSITIONS[sprite_index];
				atlas = *cards_atlas;
		}

		dst := src;
		dst.position = position;
		dst.size *= scale;

		draw_texture(atlas, src, dst, tint);
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

update_input_state :: (using s: *Input_State, events: [..] Input.Event) {
		for events {
				if it.type == .KEYBOARD {
						if it.key_code == .MOUSE_BUTTON_LEFT {
								using *s.mouse_left;
								just_pressed = it.key_pressed > 0;
								just_released = it.key_pressed <= 0;
								return;
						}
				}
		}
		{
				using *s.mouse_left;
				if just_pressed held = true;
				just_pressed = false;
				if just_released held = false;
				just_released = false;
		}
}

Input_State :: struct {
		Action_State :: struct {
				just_pressed := false;
				just_released := false;
				held := false;
		};
		mouse_left: Action_State;
}

#import "Basic";
Input :: #import "Input";
Simp :: #import "Graphics";
#import "Math";
#import "Window_Creation";
GetRect :: #import "GetRect_LeftHanded";
#import "Flat_Pool";
#import "Game_Engine";

operator == :: (a: Card, b: Card) -> bool {
		return a.value == b.value && a.suit == b.suit;
}


/**

U :: union kind: enum { A; B; C; } {
  .A ,, a: int;
  .B ,, _: struct {};
  .C ,, c: float;
}

main :: () {
  u := U.{ .B, {} };

  v := U.{ kind = .B };
}
**/
