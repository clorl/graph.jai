Action_Target :: struct {
		Kind :: enum {
				NONE;
				DISCARD;
				PILE;
				FOUNDATION;
		}
		kind := Kind.NONE;
		pile_idx := -1;
		card_idx := -1;
}

Action :: struct {
		Kind :: enum {
				NONE;
				DRAW;
				MOVE;
				STORE;
		}
		kind := Kind.NONE;
}

Action_Draw :: struct {
    #as using base : Action;
		kind = .DRAW;
		amount: int = 3;
}

Action_Move :: struct {
    #as using base : Action;
		kind = .MOVE;
		source: Action_Target;
		dest_pile_idx: int = -1;
}

Action_Store :: struct {
    #as using base : Action;
		kind = .STORE;
		source: Action_Target;
}

get_card :: (using gs: *Game_State, t: Action_Target) -> bool, Card {
		if t.kind == {
				case .DISCARD;
				if discard.count > 0 return true, discard[discard.count - 1];

				case .PILE;
				if t.pile_idx >= 0 && t.card_idx >= 0 return true, play_piles[t.pile_idx][t.card_idx];
				
				case .FOUNDATION;
				if t.pile_idx >= 0 && t.pile_idx <= 3 return true, Card.{
						suit = cast(Suit) t.pile_idx, value = fdn_piles[t.pile_idx]
				};
		}

		return false, .{};
}

is_valid_action :: (using gs: *Game_State, action: *Action) -> bool {
		if action.kind == {
				case .DRAW; return deck.count > 0;
				
				case .MOVE;
				move_action := cast(*Action_Move) action;
				if move_action.dest_pile_idx < 0 return false;
				dest_pile := play_piles[move_action.dest_pile_idx];
				dest_card := dest_pile[dest_pile.count - 1];

				success, src_card := get_card(gs, move_action.source);
				if !success return false;

				return is_red(src_card) != is_red(dest_card) && dest_card.value == src_card.value + 1;

				case .STORE;
				store_action := cast(*Action_Store) action;
				success, src_card := get_card(gs, store_action.source);
				if !success return false;
				return fdn_piles[src_card.suit] == src_card.value - 1;
		}
		
		return false;
}

execute :: (using gs: *Game_State, action: Action) {
}


is_red :: inline (c: Card) -> bool {
		return c.suit >> 1 == 1;
}

FULL_DECK_SIZE :: 52;
PLAY_PILES_COUNT :: 7;
SOLITAIRE_DECK_SIZE :: #run -> int {
		sum := 0;
		for 1..PLAY_PILES_COUNT sum += it;
		return FULL_DECK_SIZE - sum;
};
MAX_PLAY_PILE_SIZE :: #run PLAY_PILES_COUNT + 1;
DEFAULT_DECK :: #run -> [52] Card {
		deck: [52] Card;
		for s: 0..3 for v: 0..12 {
				deck[13 * s + v] = Card.{
						suit = cast(Suit)s,
						value = cast(u8) v + 1
				};
		}
		return deck;
}

Suit :: enum u8 {
		SPADES :: 0b00;
		CLUBS :: 0b01;
		HEARTS :: 0b10;
		DIAMONDS :: 0b11;
}

Card :: struct {
		suit: Suit;
		value: u8;
		face_up := false;
}

Game_State :: struct {
		deck: [..] Card;
		draw: [] Card;
		discard: [] Card;
		play_piles: [PLAY_PILES_COUNT][MAX_PLAY_PILE_SIZE] Card;
		fdn_piles: [4] u8; // Topmost card of each foundation pile
}

make_game_state :: () -> Game_State {
		gs: Game_State;
		deck_idx := 0;
		orig_deck := shuffle(DEFAULT_DECK);
		array_reserve(*gs.deck, SOLITAIRE_DECK_SIZE);

		for 0..SOLITAIRE_DECK_SIZE-1 {
				array_add(*gs.deck, orig_deck[deck_idx]);
				deck_idx += 1;
		}

		for pile_idx: 0..PLAY_PILES_COUNT-1 for 0..pile_idx {
				gs.play_piles[pile_idx][it] = orig_deck[deck_idx];
				if it == pile_idx gs.play_piles[pile_idx][it].face_up = true;
				deck_idx += 1;
		}

		gs.draw.data = gs.deck.data;
		gs.draw.count = gs.deck.count;

		return gs;
}

shuffle :: (deck: [$S] Card) -> [S] Card {
		new := deck;
		for < i: 0..(S-1) {
				j := cast(int) random_get_within_range(0., xx i);
				ci := new[i];
				new[i] = new[j];
				new[j] = ci;
		}
		return new;
}

card_to_string :: (c: Card) -> string {
		using c;
		suit_str: string = string.["b", "B", "r", "R"][suit];
		return tprint("%%", card_value_to_string(c), suit_str);
}

card_value_to_string :: (using c: Card) -> string {
		return ifx value == 1 || (value >= 10 && value <= 13) {
				string.["?", "A", "T", "J", "Q", "K"][value % 8];
		} else tprint("%", value);
}


card_is_invalid :: (c: Card) -> bool {
		return c.value == 0;
}

print :: (using gs: Game_State) {
		print("Draw: ");
		for draw {
				print("% ", format(it));
		}
		print("\n");

		print("Discard: \n");
		for discard {
				print("% ", format(it));
		}
		print("\n");

		print("Piles: \n");
		for play_piles {
				for card, idx: it if card.value != 0 print("% ", format(card));
				print("\n");
		}

		print("Foundations: ");
		for 0..3 {
				print("% ", format(Card.{ suit = cast(Suit)it, value = fdn_piles[it] }));
		}
		print("\n");
}

print :: (deck: [] Card) {
		for deck {
				print("% ", format(it));
		}
		print("\n");
}

format :: (using card: Card) -> string {
		suit_str := string.["B", "b", "R", "r"][suit];
		if value <= 13 && (value == 1 || value >= 10) {
				val_str := string.["?", "A", "T", "J", "Q", "K"][value%8];
				return tprint("%%", val_str, suit_str);
		} else {
				return tprint("%%", value, suit_str);
		}
}

#import "Basic";
#import "Random";
