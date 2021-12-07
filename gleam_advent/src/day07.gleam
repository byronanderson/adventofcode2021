import utils
import gleam/string
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day07.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.split(",")
  |> list.map(utils.assert_parse_int)
}

fn calc_part_1(data) {
  let data = data
    |> parse()
    |> list.sort(int.compare)

  assert Ok(first) = list.first(data)
  assert Ok(last) = list.last(data)

  list.range(first, last + 1)
  |> list.map(fn(i: Int) {
    cost_to_move(data, i)
  })
  |> list.sort(int.compare)
  |> list.first()
}

fn cost_to_move(crabs, location) {
  crabs
  |> list.map(fn(crab) { int.absolute_value(crab - location) })
  |> list.fold(0, fn(a, b) { a + b })
}

fn calc_part_2(data) {
  let data = data
    |> parse()
    |> list.sort(int.compare)

  assert Ok(first) = list.first(data)
  assert Ok(last) = list.last(data)

  let costs = list.range(0, last + 1)
  |> list.fold(map.new(), fn(acc, distance) {
    map.insert(acc, distance, actual_cost_to_move_spaces(distance))
  })

  list.range(first, last + 1)
  |> list.map(fn(location: Int) {
    cost_to_move_2(data, location, costs)
  })
  |> list.sort(int.compare)
  |> list.first()
}

fn cost_to_move_2(crabs, location, costs) {
  crabs
  |> list.map(fn(crab) {
    let distance = int.absolute_value(crab - location)
    assert Ok(cost) = map.get(costs, distance)
    cost
  })
  |> list.fold(0, fn(a, b) { a + b })
}

fn actual_cost_to_move_spaces(value: Int) -> Int {
  list.range(0, value + 1)
  |> list.fold(0, fn(a, b) { a + b })
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
