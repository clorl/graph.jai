wip :: () {
		gs := make_game_state();
		gs.play_piles[0][0] = .{ value = 1, suit = .DIAMONDS };
		print(gs);
		gs.deck[2] = .{};
		gs.deck[1] = .{};
		execute(*gs, Action_Draw.{});
		gs.deck[gs.discard_idx] = .{ value = 1, suit = .CLUBS };
		execute(*gs, Action_Store.{
				source = .{
						kind = .PILE,
						pile_idx = 0
				}
		});
		print(gs);
}


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
		dest: Action_Target;
}

Action_Store :: struct {
    #as using base : Action;
		source: Action_Target;
}

is_red :: inline (c: Card) -> bool {
		return c.suit >> 1 == 1;
}

get_card_ptr :: (using gs: *Game_State, using t: Action_Target) -> *Card {
		if t.kind == {
				case .DISCARD;
				assert(discard_idx >= 0);
				return *deck[discard_idx];
				case .PILE;
				assert(pile_idx >= 0 && pile_idx < PLAY_PILES_COUNT);
				assert(card_idx >= 0 && card_idx <= MAX_PLAY_PILE_SIZE);
				return *play_piles[pile_idx][card_idx];
		};
		return null;
}

execute :: (using gs: *Game_State, action: Action_Move) -> bool {
		src: *Card;
		card: Card;
		if action.source.kind == {
				case .DISCARD;
				src = *(deck[discard_idx]);
				discard_idx -= 1;

				case .PILE;
				pidx := action.source.pile_idx;
				cidx := action.source.card_idx;
				if pidx < 0 return false;
				if cidx < 0 return false;
				if ! play_piles[pidx][cidx].face_up return false;
				src = *(play_piles[pidx][cidx]);
				
				case .FOUNDATION;
				using action.source;
				if pile_idx < 0 return false;
				if fdn_piles[pile_idx] <= 0 return false;
				card = Card.{ value = fdn_piles[pile_idx], suit = cast(Suit) pile_idx };
				fdn_piles[pile_idx] -= 1;
				src = *card;
		}

		if action.dest.kind != .PILE return false;
		using action.dest;
		if pile_idx < 0 return false;
		size := count(play_piles[pile_idx]);

		if size == 0 {
				if src.value < 13 return false;
				play_piles[pile_idx][0] = src.*;
				src.* = .{};
				return true;
		}

		top_card := play_piles[pile_idx][size-1];
		if is_red(top_card) == is_red(src.*) return false;
		if top_card.value - src.value != 1 return false;
		play_piles[pile_idx][size] = src.*;
		src.* = .{};
		free(card);
		return true;
}

execute :: (using gs: *Game_State, action: Action_Store) -> bool {
		if action.source.kind == {
				case .DISCARD;
				c := deck[discard_idx];
				fdn_value := fdn_piles[c.suit];
				if fdn_value + 1 == c.value {
						deck[discard_idx] = .{};
						discard_idx -= 1;
						fdn_piles[c.suit] += 1;
						return true;
				}

				case .PILE;
				idx := action.source.pile_idx;
				if idx < 0 return false;
				size := count(play_piles[idx]);
				c := play_piles[idx][size - 1];
				fdn_value := fdn_piles[c.suit];
				if fdn_value + 1 == c.value {
						play_piles[idx][size - 1] = .{};
						fdn_piles[c.suit] += 1;
						return true;
				}
		}
		return false;
}

execute :: (using gs: *Game_State, action: Action_Draw) -> bool {
		deck_size := count(gs.deck);
		if discard_idx == deck_size - 1
		then discard_idx = (discard_idx + action.amount) % deck_size;
		else discard_idx = cast(int) clamp(discard_idx + action.amount, 0, deck_size - 1);
		return true;
}

FULL_DECK_SIZE :: 52;
PLAY_PILES_COUNT :: 7;
SOLITAIRE_DECK_SIZE :: #run -> int {
		sum := 0;
		for 1..PLAY_PILES_COUNT sum += it;
		return FULL_DECK_SIZE - sum;
};
MAX_PLAY_PILE_SIZE :: #run PLAY_PILES_COUNT + 1;
DEFAULT_DECK :: #run -> Deck(52) {
		deck: Deck(52);
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
		deck: Deck(SOLITAIRE_DECK_SIZE);
		discard_idx := -1;
		play_piles: [PLAY_PILES_COUNT]Deck(MAX_PLAY_PILE_SIZE);
		fdn_piles: [4] u8; // Topmost card of each foundation pile
}

make_game_state :: () -> Game_State {
		gs: Game_State;
		deck_idx := 0;
		orig_deck := shuffle(DEFAULT_DECK);
		for 0..SOLITAIRE_DECK_SIZE-1 {
				gs.deck[it] = orig_deck[deck_idx];
				deck_idx += 1;
		}

		for pile_idx: 0..PLAY_PILES_COUNT-1 for 0..pile_idx {
						gs.play_piles[pile_idx][it] = orig_deck[deck_idx];
						deck_idx += 1;
		}
		return gs;
}

shuffle :: (deck: Deck($S)) -> Deck(S) {
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
		value_str: string = ifx value == 1 || (value >= 10 && value <= 13) {
				string.["?", "A", "T", "J", "Q", "K"][value % 8];
		} else tprint("%", value);
		return tprint("%%", value_str, suit_str);
}


card_is_invalid :: (c: Card) -> bool {
		return c.value == 0;
}

// Sp(arse) Array
Sparray :: struct($S: int, $T: Type, $invalid_predicate: (T) -> bool){
		data: [S] T;
}

// Deck :: struct($S: int) {
// 		#as using _: Sparray(S, Card, card_is_invalid);
// }

Deck :: #bake_arguments Sparray(T=Card, invalid_predicate=card_is_invalid);

print :: (using gs: Game_State) {
		print("Deck: ");
		for deck {
				if it_index <= discard_idx continue;
				print("% ", format(it));
		}
		print("\n");

		print("Discard: \n");
		for deck {
				if it_index > discard_idx break;
				print("% % ", it_index, format(it));
		}
		print("\n");

		print("Piles: \n");
		for play_piles print(it);

		print("Foundations: ");
		for 0..3 {
				print("% ", format(Card.{ suit = cast(Suit)it, value = fdn_piles[it] }));
		}
		print("\n");
}

print :: (deck: Deck($S)) {
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

is_valid_index :: (arr: Sparray, idx: int) -> bool {
		if idx < 0 || idx >= arr.data.count return false;
		last_idx := 0;
		for arr last_idx += 1;
		return idx <= last_idx;
}

for_expansion :: (arr: Sparray($S, $T, $pred), body: Code, flags: For_Flags) #expand {
		cur_idx := 0;
		for elt, idx: arr.data {
				if pred(elt) continue;

				`it_index := cur_idx;
				`it := elt;

				cur_idx += 1;

				#insert body;
		}
}

count :: (arr: Sparray) -> int {
		last_idx := 0;
		for arr last_idx += 1;
		return last_idx;
}

operator [] :: (arr: Sparray($S, $T, $pred), idx: int) -> T {
		assert(idx >= 0, "Out of bounds access with index 0");
		for arr.data {
				if idx == it_index return it;
		}
		assert(false, "Out of bounds access on sparse array, no valid elements at index provided");
		return arr.data[0];
}

operator *[] :: (arr: *Sparray($S, $T, $pred), idx: int) -> *T {
		assert(idx >= 0, "Out of bounds access with index 0");
		for *arr.data {
				if idx == it_index return it;
		}
		assert(false, "Out of bounds access on sparse array, no valid elements at index provided");
		return null;
}

operator []= :: (arr: *Sparray($S, $T, $is_invalid), idx: int, value: Card) {
		cur_idx := 0;
		for arr.data {
				if is_invalid(it) continue;
				if cur_idx == idx {
						arr.data[it_index] = value;
						return;
				}

				cur_idx += 1;
		}
		arr.data[idx] = value;
}

#scope_file
#import "Basic";
