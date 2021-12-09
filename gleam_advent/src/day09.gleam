import utils
import gleam/string
import gleam/bool
import gleam/pair
import gleam/result
import gleam/order
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day09.txt")
  data |> string.trim()
}

type Input {
  Input(width: Int, height: Int, values: map.Map(#(Int, Int), Int))
}

fn parse(input: String) {
  let list_of_lists = input
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> list.map(list.map(_, utils.assert_parse_int))

  let height = list.length(list_of_lists)
  assert [line, .._] = list_of_lists
  let width = list.length(line)

  let values = list_of_lists
  |> list.index_fold(map.new(), fn(acc, line, y) {
    list.index_fold(line, acc, fn(acc, value, x) {
      map.insert(acc, #(x, y), value)
    })
  })

  Input(width: width, height: height, values: values)
}

fn calc_part_1(input) {
  let data = input
    |> parse()

  data
  |> low_points()
  |> list.map(pair.second)
  |> list.map(increment)
  |> int.sum()
}

fn increment(x) {
  x + 1
}

fn calc_part_2(input) {
  let data = input
    |> parse()

  let sizes = data
  |> low_points()
  |> list.map(fn(low_point) {
    let #(location, _value) = low_point
    expand(data, set.new() |> set.insert(location))
  })
  |> set.from_list()
  |> set.to_list()
  |> list.map(set.size)
  |> list.sort(int.compare)

  let [biggest1, biggest2, biggest3, .._rest] = list.reverse(sizes)
  biggest1 * biggest2 * biggest3
}

fn positions(data: Input) {
  let xs = list.range(0, data.width)
  let ys = list.range(0, data.height)

  xs
  |> list.flat_map(fn(x) {
    ys
    |> list.map(fn(y) {
      #(x, y)
    })
  })
}

fn low_points(data: Input) {
  data
  |> positions()
  |> list.map(fn(position) {
    assert Ok(value) = map.get(data.values, position)
    #(position, value)
  })
  |> list.filter(fn(element) {
    let #(position, value) = element
    let #(x, y) = position

    let less_than_neighbor = fn(position) {
      map.get(data.values, position)
      |> result.map(fn(other) {
        case int.compare(value, other) {
          order.Lt -> True
          _ -> False
        }
      })
      |> result.unwrap(True)
    }
    less_than_neighbor(#(x + 1, y)) &&
    less_than_neighbor(#(x - 1, y)) &&
    less_than_neighbor(#(x, y + 1)) &&
    less_than_neighbor(#(x, y - 1))
  })
}

fn expand(data: Input, basin: set.Set(#(Int, Int))) {
  let new_basin = set.to_list(basin)
  |> list.fold(basin, fn(acc, location) {
    let #(x, y) = location
    let check_neighbor = fn(acc, location) {
      data.values |> map.get(location) |> result.map(fn(neighbor_value) {
        case neighbor_value != 9 {
          True -> acc |> set.insert(location)
          False -> acc
        }
      })
      |> result.unwrap(acc)
    }

    acc
    |> check_neighbor(#(x + 1, y))
    |> check_neighbor(#(x - 1, y))
    |> check_neighbor(#(x, y + 1))
    |> check_neighbor(#(x, y - 1))
  })

  case set.size(new_basin) > set.size(basin) {
    True -> expand(data, new_basin)
    False -> new_basin
  }
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
