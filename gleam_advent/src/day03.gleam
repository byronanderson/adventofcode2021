import utils
import gleam/string
import gleam/list
import gleam/int
import gleam/order.{Gt, Lt, Eq}
import gleam/bitwise

fn input() {
  assert Ok(data) = utils.read_file("input_day03.txt")
  data |> string.trim()
}

fn parse(input: String) -> List(String) {
  input
  |> string.split("\n")
}

fn most_frequent_bits(data: List(String)) -> String {
  assert [first, .._rest] = data
  let length = first |> string.to_graphemes() |> list.length()

  let data = data |> list.map(string.to_graphemes)

  list.range(0, length)
  |> list.map(fn(i) {
    let count = list.fold(data, 0, fn(acc, line) {
      let Ok(item) = line |> list.at(i)
      case item {
        "0" -> acc - 1
        "1" -> acc + 1
      }
    })

    case count > 0 {
      False -> "0"
      True -> "1"
    }
  })
  |> string.join("")
}

fn binary_string_to_int(binary_string: String) -> Int {
  binary_string
  |> string.to_graphemes()
  |> binary_string_to_integer_(0)
}

fn binary_string_to_integer_(graphemes: List(String), acc: Int) {
  case graphemes {
    ["0", ..rest] -> binary_string_to_integer_(rest, acc * 2)
    ["1", ..rest] -> binary_string_to_integer_(rest, acc * 2 + 1)
    [] -> acc
  }
}

fn calc_part_1(data) {
  let gamma = data
  |> parse()
  |> most_frequent_bits()
  |> binary_string_to_int()

  let epsilon = bitwise.exclusive_or(gamma, 4095)

  gamma * epsilon
}

fn find_oxygen_generator_bits(data: List(String)) -> String {
  let data = data |> list.map(string.to_graphemes)

  assert [first, .._rest] = data
  let length = first |> list.length()

  assert [result] = list.range(0, length)
  |> list.fold(data, fn(data, i) {
    case list.length(data) {
      1 -> data
      _ -> {
        let count = list.fold(data, 0, fn(acc, line) {
          let Ok(item) = line |> list.at(i)
          case item {
            "0" -> acc - 1
            "1" -> acc + 1
          }
        })

        let relevant = case int.compare(count, 0) {
          Gt -> "1"
          Eq -> "1"
          Lt -> "0"
        }

        data
        |> list.filter(fn(el) {
          assert Ok(at_position) = list.at(el, i)
          at_position == relevant
        })
      }
    }
  })
  result
  |> string.join("")
}

fn find_co2_scrubber_bits(data: List(String)) -> String {
  let data = data |> list.map(string.to_graphemes)

  assert [first, .._rest] = data
  let length = first |> list.length()

  assert [result] = list.range(0, length)
  |> list.fold(data, fn(data, i) {
    case list.length(data) {
      1 -> data
      _ -> {
        let count = list.fold(data, 0, fn(acc, line) {
          let Ok(item) = line |> list.at(i)
          case item {
            "0" -> acc - 1
            "1" -> acc + 1
          }
        })

        let relevant = case int.compare(count, 0) {
          Gt -> "0"
          Eq -> "0"
          Lt -> "1"
        }

        data
        |> list.filter(fn(el) {
          assert Ok(at_position) = list.at(el, i)
          at_position == relevant
        })
      }
    }
  })
  result
  |> string.join("")
}

fn calc_part_2(data) {
  let data = parse(data)
  let oxygen_generator_rating = data
  |> find_oxygen_generator_bits()
  |> binary_string_to_int()

  let co2_scrubber_rating = data
  |> find_co2_scrubber_bits()
  |> binary_string_to_int()

  oxygen_generator_rating * co2_scrubber_rating
}

pub fn part1() {
  assert 1 = binary_string_to_int("1")
  assert 0 = binary_string_to_int("0")
  assert 2 = binary_string_to_int("10")
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
