import utils
import gleam/string
import gleam/bit_string
import gleam/result
import gleam/io
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

type Position {
  Position(x: Int, y: Int)
}

type Fold {
  Fold(axis: FoldAxis, location: Int)
}

type FoldAxis {
  X
  Y
}

type Input {
  Input(folds: List(Fold), dots: List(Position))
}

fn input() {
  assert Ok(data) = utils.read_file("input_day13.txt")
  data |> string.trim()
}

fn parse(input: String) -> Input {
  assert [dots_string, folds_string] = input
    |> string.split("\n\n")

  Input(
    dots: parse_dots(dots_string),
    folds: parse_folds(folds_string)
  )
}

fn parse_dots(dots_string: String) -> List(Position) {
  dots_string
  |> string.split("\n")
  |> list.map(parse_dot)
}

fn parse_dot(dot_string: String) -> Position {
  assert [x, y] = dot_string
    |> string.split(",")
    |> list.map(utils.assert_parse_int)

  Position(x, y)
}

fn parse_folds(folds_string: String) -> List(Fold) {
  folds_string
  |> string.split("\n")
  |> list.map(parse_fold)
}

fn parse_fold(fold_string: String) -> Fold {
  case bit_string.from_string(fold_string) {
    <<"fold along x=":utf8, rest:binary>> -> Fold(X, utils.assert_parse_int(bit_string.to_string(rest) |> result.unwrap("")))
    <<"fold along y=":utf8, rest:binary>> -> Fold(Y, utils.assert_parse_int(bit_string.to_string(rest) |> result.unwrap("")))
  }
}

fn process_folds(dots: List(Position), folds: List(Fold)) {
  let input = set.from_list(dots)
  folds
  |> list.fold(input, fn(dots, fold) {
    process_fold(dots, fold)
  })
}

fn process_fold(dots: set.Set(Position), fold: Fold) -> set.Set(Position) {
  let #(below_fold, above_fold) = dots
  |> set.to_list()
  |> list.partition(fn(dot: Position) {
    case fold.axis {
      X -> dot.x < fold.location
      Y -> dot.y < fold.location
    }
  })

  let folded_over = above_fold
  |> list.map(fn(dot: Position) {
    case fold.axis {
      X -> Position(..dot, x: fold.location * 2 - dot.x)
      Y -> Position(..dot, y: fold.location * 2 - dot.y)
    }
  })

  let result = list.append(below_fold, folded_over)
  |> set.from_list()
  result
}

fn position_x(loc: Position) {
  loc.x
}

fn position_y(loc: Position) {
  loc.y
}

fn calc_part_1(data) {
  let data = data |> parse()
  assert [first_fold, ..] = data.folds
  let data = Input(..data, folds: [first_fold])

  process_folds(data.dots, data.folds)
  |> set.size()
}

fn calc_part_2(data) {
  let data = data |> parse()
  let result = process_folds(data.dots, data.folds)

  let sorted_x = result |> set.to_list() |> list.map(position_x) |> list.sort(int.compare)
  let sorted_y = result |> set.to_list() |> list.map(position_y) |> list.sort(int.compare)

  let max_x = sorted_x |> list.last() |> result.unwrap(0)
  let max_y = sorted_y |> list.last() |> result.unwrap(0)

  let xs = list.range(0, max_x + 1)
  let ys = list.range(0, max_y + 1)

  ys
  |> list.each(fn(y) {
    xs
    |> list.each(fn(x) {
      case set.contains(result, Position(x, y)) {
        True -> io.print("X")
        False -> io.print(" ")
      }
    })
    io.print("\n")
  })
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
