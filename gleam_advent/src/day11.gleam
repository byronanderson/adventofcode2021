import utils
import gleam/string
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day11.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    line
    |> string.to_graphemes()
    |> list.map(utils.assert_parse_int)
  })
  |> list.index_map(fn(y, line) {
    line
    |> list.index_map(fn(x, value) {
      #(#(x, y), value)
    })
  })
  |> list.flatten()
}

type Position = #(Int, Int)
type Value = Int
type Octopus = #(Position, Value)

fn evolve(input: List(#(Position, Value))) {
  input
  |> list.map(fn(octopus) {
    pair.map_second(octopus, increment)
  })
  |> chain_flash(set.new())
  |> pair.map_first(fn(input) { reset_flashed(input) })
}

fn chain_flash(input: List(Octopus), already_flashed: set.Set(Position)) {
  let newly_flashing = input
  |> list.filter(fn(octopus) {
    let #(_position, value) = octopus
    value > 9
  })
  |> list.filter(fn(octopus) {
    let #(position, _value) = octopus

    set.contains(already_flashed, position)
    |> bool.negate()
  })

  let new_already_flashed = newly_flashing
  |> list.fold(already_flashed, fn(flashing, flashing_octopus) {
    let #(position, _value) = flashing_octopus
    set.insert(flashing, position)
  })

  let new_octopuses = newly_flashing
  |> list.fold(input, fn(input, flashing_octopus) {
    let #(position, _value) = flashing_octopus

    input
    |> execute_flash(position)
  })

  case list.length(newly_flashing) {
    0 -> #(new_octopuses, set.size(already_flashed))
    _ -> chain_flash(new_octopuses, new_already_flashed)
  }
}

fn reset_flashed(input: List(Octopus)) {
  input
  |> list.map(fn(octopus) {
    case octopus {
      #(position, value) if value > 9 -> #(position, 0)
      other -> other
    }
  })
}

fn execute_flash(input: List(Octopus), position: Position) -> List(Octopus) {
  let #(x, y) = position
  let leftx = x - 1
  let rightx = x + 1
  let topy = y - 1
  let bottomy = y + 1

  input
  |> list.map(fn(octopus) {
    let #(position, value) = octopus
    case position {
      #(xx, yy) if xx == rightx && yy == bottomy -> #(position, value + 1)
      #(xx, yy) if xx == x && yy == bottomy -> #(position, value + 1)
      #(xx, yy) if xx == leftx && yy == bottomy -> #(position, value + 1)
      #(xx, yy) if xx == rightx && yy == y -> #(position, value + 1)
      #(xx, yy) if xx == leftx && yy == y -> #(position, value + 1)
      #(xx, yy) if xx == rightx && yy == topy -> #(position, value + 1)
      #(xx, yy) if xx == x && yy == topy -> #(position, value + 1)
      #(xx, yy) if xx == leftx && yy == topy -> #(position, value + 1)
      _ -> octopus
    }
  })
}

fn increment(x: Int) -> Int { x + 1 }

fn evolve_until_synchronized(data, target_octopuses, steps) {
  case evolve(data) {
    #(_data, flashes) if flashes == target_octopuses -> steps + 1
    #(data, _) -> evolve_until_synchronized(data, target_octopuses, steps + 1)
  }
}

fn calc_part_1(input, iterations: Int) {
  let data = parse(input)
  list.range(0, iterations)
  |> list.fold(#(data, 0), fn(acc, _) {
    let #(data, flashes) = acc
    let #(new_data, new_flashes) = evolve(data)
    #(new_data, flashes + new_flashes)
  })
  |> pair.second()
}

fn calc_part_2(input) {
  let data = parse(input)

  let num_octopuses = list.length(data)

  evolve_until_synchronized(data, num_octopuses, 0)
}

pub fn part1() {
  let example = "11111
19991
19191
19991
11111"
  assert 9 = calc_part_1(example, 2)
  calc_part_1(input(), 100)
}

pub fn part2() {
  calc_part_2(input())
}
