import utils
import gleam/string
import gleam/regex
import gleam/option
import gleam/bool
import gleam/iterator
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day21.txt")
  data |> string.trim()
}

type Input {
  Input(player_1_starting_position: Int, player_2_starting_position: Int)
}

fn parse(input: String) {
  assert [player_1_starting_position, player_2_starting_position] = input
  |> string.split("\n")
  |> list.map(parse_starting_position)

  Input(player_1_starting_position: player_1_starting_position, player_2_starting_position: player_2_starting_position)
}

type Die = iterator.Iterator(Int)

fn make_die() -> Die {
  iterator.unfold(0, fn(index) {
    iterator.Next(element: index, accumulator: index + 1)
  })
}
fn roll(die: Die) -> #(Int, Die) {
  assert iterator.Next(index, die) = iterator.step(die)
  #({ index + 1 } % 100, die)
}

fn num_rolls(die) {
  assert [num] = iterator.take(die, 1) |> iterator.to_list()
  num
}

type Player {
  Player1
  Player2
}

type PlayerState {
  PlayerState(index: Int, score: Int)
}

type State {
  State(next_turn: Player, player_1: PlayerState, player_2: PlayerState, die: Die)
}

type Winner {
  Winner(player: Player, player_1_score: Int, player_2_score: Int, die: Die)
}

// type Die {
//   DeterministicDie(next_index: Int, sides: Int)
// }

// fn roll_die(die: Die) -> #(Int, Die) {
  // case die {
  //   DeterministicDie(next_index: index, sides: sides) ->
  //     #(index + 1, DeterministicDie(..die, next_index: { index + 1 } % 100))
  // }
// }

fn parse_starting_position(input: String) {
  assert Ok(re) = regex.from_string("Player \\d starting position: (\\d+)")
  assert [regex.Match(_, [option.Some(position_string)])] = regex.scan(re, input)
  utils.assert_parse_int(position_string)
}

fn play(state: State) -> Winner {
  let State(next_turn: current_player, player_1: player_1, player_2: player_2, die: die) = state;
  let #(roll1, die) = roll(die)
  let #(roll2, die) = roll(die)
  let #(roll3, die) = roll(die)

  let rolls = roll1 + roll2 + roll3

  let #(next_player, player_1, player_2) = case current_player {
    Player1 -> #(Player2, update_player_state(player_1, rolls), player_2)
    Player2 -> #(Player1, player_1, update_player_state(player_2, rolls))
  }

  let new_state = State(next_turn: next_player, player_1: player_1, player_2: player_2, die: die)

  case winner(new_state) {
    option.Some(winner) -> winner
    option.None -> play(new_state)
  }
}

fn update_player_state(state: PlayerState, rolls: Int) -> PlayerState {
  let PlayerState(index: index, score: score) = state

  let new_index = { index + rolls } % 10

  let position = new_index + 1

  let new_score = score + position

  PlayerState(index: new_index, score: new_score)
}

fn winner(state: State) {
  case #(state.player_1.score >= 1000, state.player_2.score >= 1000) {
    #(True, False) -> option.Some(Winner(player: Player1, player_1_score: state.player_1.score, player_2_score: state.player_2.score, die: state.die))
    #(False, True) -> option.Some(Winner(player: Player2, player_1_score: state.player_1.score, player_2_score: state.player_2.score, die: state.die))
    #(False, False) -> option.None
  }
}

fn calc_part_1(data: Input) {
  let die = make_die()

  let winner = play(State(next_turn: Player1, player_1: PlayerState(index: data.player_1_starting_position - 1, score: 0), player_2: PlayerState(index: data.player_2_starting_position - 1, score: 0), die: die))

  let other_player_score = case winner.player {
    Player1 -> winner.player_2_score
    Player2 -> winner.player_1_score
  }

  other_player_score * num_rolls(winner.die)
}

// 3 rolls of 3 sided die:

// first toss generates 3 universes:
// 1 universe 1
// 1 universe 2
// 1 universe 3

// second toss splits those 3 into 9
// 9 universes
// 1 universe 11
// 1 universe 12
// 1 universe 13
// 1 universe 21
// 1 universe 22
// 1 universe 23
// 1 universe 31
// 1 universe 32
// 1 universe 33

// third toss splits those 9 into 27
// 27 universes
// 1 universe 111 = 3
// 1 universe 112 = 4
// 1 universe 113 = 5
// 1 universe 121 = 4
// 1 universe 122 = 5
// 1 universe 123 = 6
// 1 universe 131 = 5
// 1 universe 132 = 6
// 1 universe 133 = 7
// 1 universe 211 = 4
// 1 universe 212 = 5
// 1 universe 213 = 6
// 1 universe 221 = 5
// 1 universe 222 = 6
// 1 universe 223 = 7
// 1 universe 231 = 6
// 1 universe 232 = 7
// 1 universe 233 = 8
// 1 universe 311 = 5
// 1 universe 312 = 6
// 1 universe 313 = 7
// 1 universe 321 = 6
// 1 universe 322 = 7
// 1 universe 323 = 8
// 1 universe 331 = 7
// 1 universe 332 = 8
// 1 universe 333 = 9


// 3 once
// 4 thrice
// 5 6 times
// 6 7 times
// 7 6 times
// 8 thrice
// 9 once
//
// 1 + 3 + 6 + 7 + 6 + 3 + 1 = 27 check

type PlayersState {
  OngoingGame(#(PlayerState, PlayerState))
  Over(winner: Player)
}
type State2 {
  State2(next_turn: Player, universes: map.Map(PlayersState, Int))
}

fn play2(state: State2) {
  let dice_universe_distribution = [
    #(3, 1),
    #(4, 3),
    #(5, 6),
    #(6, 7),
    #(7, 6),
    #(8, 3),
    #(9, 1)
  ]

  let current_player = state.next_turn

  let new_universes = state.universes
  |> map.to_list()
  |> list.fold(map.new(), fn(acc, element) {
    let #(universe, original_universe_count) = element
    case universe {
      OngoingGame(#(player_1, player_2)) -> {
        dice_universe_distribution
        |> list.fold(acc, fn(acc, dice_frequency) {
          let #(rolls, num_universes) = dice_frequency

          let #(player_1, player_2) = case current_player {
            Player1 -> #(update_player_state(player_1, rolls), player_2)
            Player2 -> #(player_1, update_player_state(player_2, rolls))
          }

          let result = case winner2(player_1, player_2) {
            option.Some(player) -> Over(winner: player)
            option.None -> OngoingGame(#(player_1, player_2))
          }

          increment_universes(acc, result, original_universe_count * num_universes)
        })
      }
      Over(_) -> increment_universes(acc, universe, original_universe_count)
    }
  })

  let next_player = case current_player {
    Player1 -> Player2
    Player2 -> Player1
  }

  let all_universes_completed = new_universes
  |> map.keys()
  |> list.all(fn(universe) {
    case universe {
      Over(_) -> True
      _ -> False
    }
  })

  case all_universes_completed {
    True -> new_universes
    False -> play2(State2(next_turn: next_player, universes: new_universes))
  }
}

fn increment_universes(universes, state, count) {
  universes
  |> map.update(state, fn(value) {
    case value {
      option.Some(existing) -> existing + count
      option.None -> count
    }
  })
}

fn winner2(player_1: PlayerState, player_2: PlayerState) -> option.Option(Player) {
  case #(player_1.score >= 21, player_2.score >= 21) {
    #(True, False) -> option.Some(Player1)
    #(False, True) -> option.Some(Player2)
    #(False, False) -> option.None
  }
}


fn calc_part_2(data: Input) {
  let starter_universe = OngoingGame(#(PlayerState(index: data.player_1_starting_position - 1, score: 0), PlayerState(index: data.player_2_starting_position - 1, score: 0)))

  let starter_universes = map.new() |> map.insert(starter_universe, 1)
  play2(State2(next_turn: Player1, universes: starter_universes))
  |> utils.inspect()
  |> map.to_list()
  |> list.map(pair.second)
  |> list.sort(int.compare)
}

pub fn part1() {
  let die = make_die()
  let die = list.range(0, 100)
  |> list.fold(die, fn(die, _) {
    let #(_value, die) = roll(die)
    die
  })
  assert 100 = num_rolls(die)
  assert #(1, _die) = roll(die)

  assert 739785 = calc_part_1(Input(player_1_starting_position: 4, player_2_starting_position: 8))
  calc_part_1(input() |> parse())
}

pub fn part2() {
  calc_part_2(input() |> parse())
}
