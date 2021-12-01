import utils
import gleam/string
import gleam/list
import gleam/int

fn input() {
  assert Ok(data) = utils.read_file("input_day01.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) {
    assert Ok(data) = int.parse(line)
    data
  })
}

fn calc_part_1(data) {
  data
  |> parse()
  |> list.window_by_2()
  |> list.filter(fn(points) {
    let #(point1, point2) = points
    point2 > point1
  })
  |> list.length()
}

fn calc_part_2(data) {
  data
  |> parse()
  |> list.window(4)
  |> list.filter(fn(points) {
    assert [point1, _, _, point2] = points
    point2 > point1
  })
  |> list.length()
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
