import utils
import gleam/string
import gleam/option
import gleam/order
import gleam/list
import gleam/map
import gleam/int

fn input() {
  assert Ok(data) = utils.read_file("input_day05.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.split("\n")
  |> list.map(fn(line: String) {
    assert [start, end] = string.split(line, " -> ")
    #(parse_coordinate(start), parse_coordinate(end))
  })
}

fn parse_coordinate(data: String) {
  assert [x, y] = data
  |> string.split(",")
  |> list.map(assert_parse_int)

  #(x, y)
}

fn assert_parse_int(input: String) -> Int {
  assert Ok(data) = int.parse(input)
  data
}

fn count_overlaps(lines) {
  lines
  |> list.fold(map.new(), fill_in_line)
  |> map.to_list()
  |> list.filter(fn(data) {
    let #(_, count) = data
    count > 1
  })
  |> list.length()
}

fn calc_part_1(data) {
  data
  |> parse()
  |> list.filter(fn(line) {
    let #(#(x1, y1), #(x2, y2)) = line
    x1 == x2 || y1 == y2
  })
  |> count_overlaps()
}

fn fill_in_line(locations, line) {
  line
  |> line_locations()
  |> list.fold(locations, fn(acc, location) {
    acc |> map.update(location, fn(data) {
      case data {
        option.Some(data) -> data + 1
        option.None -> 1
      }
    })
  })
}

fn line_locations(line) {
  let #(#(x1, y1), #(x2, y2)) = line
  let x_movement = x2 - x1
  let y_movement = y2 - y1
  let iterations = int.max(int.absolute_value(x_movement), int.absolute_value(y_movement))

  list.range(0, iterations + 1)
  |> list.map(fn(i) {
    let x = case int.compare(x1, x2) {
      order.Gt -> x1 - i
      order.Eq -> x1
      order.Lt -> x1 + i
    }
    let y = case int.compare(y1, y2) {
      order.Gt -> y1 - i
      order.Eq -> y1
      order.Lt -> y1 + i
    }

    #(x, y)
  })
}

fn calc_part_2(data) {
  data
  |> parse()
  |> count_overlaps()
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
