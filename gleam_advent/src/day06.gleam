import utils
import gleam/string
import gleam/option
import gleam/pair
import gleam/list
import gleam/map
import gleam/int

fn input() {
  assert Ok(data) = utils.read_file("input_day06.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.split(",")
  |> list.map(assert_parse_int)
  |> list.fold(map.new(), fn(acc, life) {
    insert_lanternfish(acc, life, 1)
  })
}

fn insert_lanternfish(data: Data, life: Int, amount: Int) -> Data {
  data
  |> map.update(life, fn(data) {
    case data {
      option.Some(amt) -> amt + amount
      option.None -> amount
    }
  })
}

fn assert_parse_int(input: String) -> Int {
  assert Ok(data) = int.parse(input)
  data
}

type Data = map.Map(Int, Int)
type Entry = #(Int, Int)

fn evolve(data: Data) -> Data {
  data
  |> map.to_list()
  |> list.flat_map(fn(entry: Entry) -> List(Entry) {
    let #(life, amount) = entry
    case life {
      0 -> [#(6, amount), #(8, amount)]
      n -> [#(n - 1, amount)]
    }
  })
  |> list.fold(map.new(), fn(acc: Data, entry: Entry) -> Data {
    let #(life, amount) = entry
    insert_lanternfish(acc, life, amount)
  })
}

fn calc(data, iterations) {
  let input = data |> parse()

  list.range(0, iterations)
  |> list.fold(input, fn(acc, _) {
    evolve(acc)
  })
  |> map.to_list()
  |> list.map(pair.second)
  |> list.reduce(fn(a, b) { a + b })
}

pub fn part1() {
  calc(input(), 80)
}

pub fn part2() {
  calc(input(), 256)
}
