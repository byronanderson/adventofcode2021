import utils
import gleam/string
import gleam/bool
import gleam/result
import gleam/pair
import gleam/option
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day14.txt")
  data |> string.trim()
}

type Input {
  Input(template: String, rules: map.Map(#(String, String), String))
}

fn parse(input: String) -> Input {
  assert [template, rules_string] = input
    |> string.split("\n\n")

  Input(
    template: template,
    rules: parse_rules(rules_string)
  )
}

fn parse_rules(rules_string: String) {
  rules_string
  |> string.split("\n")
  |> list.map(parse_rule)
  |> map.from_list()
}

fn parse_rule(rule_string: String) {
  assert [adjacents, insertion] = rule_string
    |> string.split(" -> ")

  assert [left, right] = adjacents |> string.to_graphemes()

  #(#(left, right), insertion)
}

fn evolve(input: map.Map(#(String, String), Int), rules: map.Map(#(String, String), String)) {
  input
  |> map.to_list()
  |> list.fold(input, fn(acc, el) {
    let #(pair, count) = el
    let #(first, second) = pair
    assert Ok(insertion) = map.get(rules, pair)

    acc
    |> add_pair_count(pair, -1 * count)
    |> add_pair_count(#(first, insertion), count)
    |> add_pair_count(#(insertion, second), count)
  })
  |> utils.inspect()
}

fn add_pair_count(data, pair, count) {
  map.update(data, pair, fn(value) {
    case value {
      option.Some(num) -> num + count
      option.None -> count
    }
  })
}

fn increment_count(data, pair) {
  add_pair_count(data, pair, 1)
}

fn calc(input, steps) {
  let input = input |> parse()

  assert Ok(first_letter) = input.template |> string.to_graphemes() |> list.first()
  let data = input.template |> string.to_graphemes()
  |> list.window_by_2()
  |> list.fold(map.new(), increment_count)

  let output = list.range(0, steps)
  |> list.fold(data, fn(acc, i) {
    evolve(acc, input.rules)
  })
  |> map.to_list()

  let sorted_lengths = output
  |> list.map(fn(el) {
    #(
      el |> pair.first() |> pair.second(),
      el |> pair.second()
    )
  })
  |> list.append([#(first_letter, 1)], _)
  |> list.fold(map.new(), fn(acc, counter) {
    let #(letter, new_count) = counter
    let count = acc |> map.get(letter) |> result.unwrap(0)
    map.insert(acc, letter, count + new_count)
  })
  |> map.to_list()
  |> list.map(fn(el) {
    let #(_, count) = el
    count
  })
  |> list.sort(int.compare)

  assert Ok(first) = list.first(sorted_lengths)
  assert Ok(last) = list.last(sorted_lengths)

  last - first
}

fn calc_part_2(data) {
  -1
}

pub fn part1() {
  assert 1588 = calc("NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C", 10)
  calc(input(), 10)
}

pub fn part2() {
  calc(input(), 40)
}
