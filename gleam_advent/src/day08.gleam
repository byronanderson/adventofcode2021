import utils
import gleam/string
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day08.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.split("\n")
  |> list.map(parse_row)
}

fn parse_row(input: String) {
  assert [first_part, second_part] = input
    |> string.split(" | ")
  let first_part = first_part
    |> string.split(" ")
    |> list.map(string_sort)
  let second_part = second_part
    |> string.split(" ")
    |> list.map(string_sort)

  #(first_part, second_part)
}

fn string_sort(string) {
  string
  |> string.to_graphemes()
  |> set.from_list()
}

fn calc_part_1(data) {
  data
  |> parse()
  |> list.map(pair.second)
  |> list.map(fn(values) {
    values
    |> list.filter(fn(value) {
      case value |> set.to_list() |> list.length() {
        2 -> True
        3 -> True
        4 -> True
        7 -> True
        _ -> False
      }
    })
    |> list.length()
  })
  |> int.sum()
}

fn calc_part_2(data) {
  data
  |> parse()
  |> list.map(fn(value) {
    let #(patterns, displayed) = value

    let mappings = patterns |> deduce_mappings()

    displayed
    |> list.index_map(fn(index, word) {
      assert Ok(value) = map.get(mappings, word)
      value * exp(10, 3 - index)
    })
    |> int.sum()
  })
  |> int.sum()
}

fn exp(value: Int, power: Int) {
  case power {
    0 -> 1
    _ -> exp(value, power - 1) * value
  }
}

fn set_length(input) {
  input
  |> set.to_list()
  |> list.length()
}

fn deduce_mappings(data) {
  assert [one_segments] = data |> list.filter(fn(item) {
    set_length(item) == 2
  })
  assert [four_segments] = data |> list.filter(fn(item) {
    set_length(item) == 4
  })
  assert [eight_segments] = data |> list.filter(fn(item) {
    set_length(item) == 7
  })
  assert [seven_segments] = data |> list.filter(fn(item) {
    set_length(item) == 3
  })
  assert [six_segments] = data |> list.filter(fn(item) {
    set_length(item) == 6 && bool.negate(is_superset(item, seven_segments))
  })
  assert [three_segments] = data |> list.filter(fn(item) {
    set_length(item) == 5 && is_superset(item, seven_segments)
  })
  assert [nine_segments] = data |> list.filter(fn(item) {
    set_length(item) == 6 && is_superset(item, three_segments)
  })
  assert [two_segments] = data |> list.filter(fn(item) {
    set_length(item) == 5 && bool.negate(is_superset(nine_segments, item))
  })
  assert [zero_segments] = data |> list.filter(fn(item) {
    set_length(item) == 6 && bool.negate(item == nine_segments || item == six_segments)
  })
  assert [five_segments] = data |> list.filter(fn(item) {
    set_length(item) == 5 && bool.negate(item == three_segments || item == two_segments)
  })

  map.new()
  |> map.insert(zero_segments, 0)
  |> map.insert(one_segments, 1)
  |> map.insert(two_segments, 2)
  |> map.insert(three_segments, 3)
  |> map.insert(four_segments, 4)
  |> map.insert(five_segments, 5)
  |> map.insert(six_segments, 6)
  |> map.insert(seven_segments, 7)
  |> map.insert(eight_segments, 8)
  |> map.insert(nine_segments, 9)
}

fn is_superset(superset, subset) {
  let in_both = set.intersection(superset, subset)

  set_length(in_both) == set_length(subset)
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
