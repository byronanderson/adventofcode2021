import utils
import gleam/string
import gleam/result
import gleam/iterator
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

type SNumber {
  Pair(left: SNumber, right: SNumber)
  Literal(value: Int)
}

fn reduce_s_number(input: SNumber) -> SNumber {
  case find_too_deep_thing(input, []) {
    Ok(location) -> explode(input, location) |> reduce_s_number()
    Error(Nil) -> {
      case find_literal_greater_than_10(input) {
        Ok(#(val, location)) -> split(input, location, val) |> reduce_s_number()
        Error(Nil) -> input
      }
    }
  }
}

fn find_literal_greater_than_10(input: SNumber) -> Result(#(Int, List(Direction)), Nil) {
  input
  |> literals()
  |> list.find(fn(literal) {
    let #(val, _) = literal

    val >= 10
  })
}

fn split(input: SNumber, location: List(Direction), value: Int) -> SNumber {
  let left = value / 2
  let right = value / 2 + value % 2
  assert Ok(result) = replace(input, location, Pair(Literal(left), Literal(right)))
  result
}

type Direction {
  Left
  Right
}

fn find_too_deep_thing(input: SNumber, directions: List(Direction)) -> Result(#(List(Direction), Int, Int), Nil) {
  let check = fn(number: SNumber, direction: Direction) {
    find_too_deep_thing(number, [direction, ..directions])
  }
  traverse(input, [])
  |> iterator.map(fn(node) {
    case node {
      #(Pair(Literal(left), Literal(right)), directions)  -> {
        case list.length(directions) >= 4 {
          True -> Ok(#(directions, left, right))
          False -> Error(Nil)
        }
      }
      _ -> Error(Nil)
    }
  })
  |> iterator.to_list()
  |> result.values()
  |> list.first()
}

fn replace(input: SNumber, location: List(Direction), replacement: SNumber) -> Result(SNumber, Nil) {
  case #(location, input) {
    #([], _) -> Ok(replacement)
    #([Left, ..other_directions], Pair(left, right)) -> {
      replace(left, other_directions, replacement)
      |> result.map(fn(successfully_replaced_subvalue) {
        Pair(successfully_replaced_subvalue, right)
      })
    }
    #([Right, ..other_directions], Pair(left, right)) -> {
      replace(right, other_directions, replacement)
      |> result.map(fn(successfully_replaced_subvalue) {
        Pair(left, successfully_replaced_subvalue)
      })
    }
    _ -> Error(Nil)
  }
}

fn traverse(input: SNumber, directions: List(Direction)) -> iterator.Iterator(#(SNumber, List(Direction))) {
  let recurse_traverse = fn(input: SNumber, direction: Direction) {
    traverse(input, list.append(directions, [direction]))
  }
  case input {
    Pair(left, right) -> {
      iterator.single(#(input, directions))
      |> iterator.append(recurse_traverse(left, Left))
      |> iterator.append(recurse_traverse(right, Right))
    }
    Literal(_) -> iterator.single(#(input, directions))
  }
}


fn is_left_of(location_1, location_2) {
  case #(location_1, location_2) {
    #([x, ..location_1_rest], [y, ..location_2_rest]) if x == y -> is_left_of(location_1_rest, location_2_rest)
    #([Left, .._], [Right, .._]) -> True
    _ -> False
  }
}

fn is_right_of(location_1, location_2) {
  case #(location_1, location_2) {
    #([x, ..location_1_rest], [y, ..location_2_rest]) if x == y -> is_right_of(location_1_rest, location_2_rest)
    #([Right, .._], [Left, .._]) -> True
    _ -> False
  }
}

fn literals(input: SNumber) -> List(#(Int, List(Direction))) {
  let is_literal = fn(val) {
    case val {
      #(Literal(_), _) -> True
      _ -> False
    }
  }

  traverse(input, [])
  |> iterator.filter(is_literal)
  |> iterator.to_list()
  |> list.map(fn(literal) {
    assert #(Literal(val), location) = literal
    #(val, location)
  })
}

fn find_literal_right(input: SNumber, location: List(Direction)) -> Result(#(Int, List(Direction)), Nil) {
  input
  |> literals()
  |> list.find(fn(el) {
    let #(_, subject_location) = el
    is_right_of(subject_location, location)
  })
}

fn find_literal_left(input: SNumber, location: List(Direction)) -> Result(#(Int, List(Direction)), Nil) {
  input
  |> literals()
  |> list.reverse()
  |> list.find(fn(el) {
    let #(_, subject_location) = el
    is_left_of(subject_location, location)
  })
}

fn explode(input: SNumber, replacement_data: #(List(Direction), Int, Int)) {
  // make the location have a 0
  // find the immediately left value and add the left literal to it
  // find the immediately right value and add the right literal to it

  let #(exploded_location, exploded_left_value, exploded_right_value) = replacement_data
  let left_literal_replacement = find_literal_left(input, exploded_location)
  |> result.map(fn(data) {
    let #(value, location) = data
    #(location, Literal(value + exploded_left_value))
  })

  let right_literal_replacement = find_literal_right(input, exploded_location)
  |> result.map(fn(data) {
    let #(value, location) = data
    #(location, Literal(value + exploded_right_value))
  })


  let incorporate_change = fn(input: SNumber, replacement: Result(#(List(Direction), SNumber), Nil)) -> SNumber {
    case replacement {
      Ok(#(location, value)) -> {
        assert Ok(number) = replace(input, location, value)
        number
      }
      Error(Nil) -> input
    }
  }

  assert Ok(input) = input |> replace(exploded_location, Literal(0))

  input
  |> incorporate_change(left_literal_replacement)
  |> incorporate_change(right_literal_replacement)
}

fn magnitude(value: SNumber) {
  case value {
    Pair(left, right) -> 3 * magnitude(left) + 2 * magnitude(right)
    Literal(value) -> value
  }
}

fn calc_part_1(data) {
  assert Ok(result_number) = data
  |> list.reduce(fn(left, right) {
    Pair(left, right) |> reduce_s_number()
  })


  magnitude(result_number)
}

fn calc_part_2(data) {
  data
  |> list.combinations(2)
  |> list.flat_map(fn(number) {
    assert [left, right] = number

    [
      Pair(left, right)
      |> reduce_s_number()
      |> magnitude(),
      Pair(left, right)
      |> reduce_s_number()
      |> magnitude()
    ]
  })
  |> list.sort(int.compare)
  |> list.last()
}

pub fn part1() {
  assert Ok(Literal(2)) = replace(Literal(1), [], Literal(2))
  assert Error(Nil) = replace(Literal(1), [Left], Literal(2))
  assert Ok(#(1, [Left])) = find_literal_left(Pair(Literal(1), Literal(2)), [Right])
  assert True = is_left_of([Left], [Right])

  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}

fn input() {
  [
    Pair(Pair(Pair(Literal(0),Pair(Literal(4),Literal(4))),Literal(6)),Pair(Pair(Pair(Literal(7),Literal(6)),Literal(6)),Pair(Pair(Literal(5),Literal(3)),Pair(Literal(3),Literal(2))))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(6)),Pair(Literal(1),Literal(7))),Pair(Literal(5),Literal(8))),Pair(Pair(Literal(9),Literal(7)),Pair(Literal(9),Literal(6)))),
    Pair(Pair(Pair(Literal(2),Pair(Literal(7),Literal(1))),Pair(Pair(Literal(8),Literal(2)),Pair(Literal(9),Literal(3)))),Literal(3)),
    Pair(Pair(Pair(Pair(Literal(2),Literal(1)),Literal(6)),Literal(2)),Literal(4)),
    Pair(Pair(Pair(Pair(Literal(0),Literal(3)),Literal(0)),Literal(6)),Pair(Pair(Literal(9),Pair(Literal(0),Literal(8))),Pair(Pair(Literal(2),Literal(1)),Pair(Literal(0),Literal(2))))),
    Pair(Pair(Pair(Literal(5),Literal(1)),Pair(Pair(Literal(0),Literal(5)),Literal(1))),Pair(Pair(Pair(Literal(9),Literal(9)),Pair(Literal(8),Literal(7))),Literal(7))),
    Pair(Pair(Pair(Pair(Literal(0),Literal(2)),Literal(8)),Literal(8)),Pair(Literal(0),Pair(Literal(7),Pair(Literal(2),Literal(7))))),
    Pair(Pair(Pair(Pair(Literal(3),Literal(8)),Pair(Literal(6),Literal(4))),Pair(Pair(Literal(2),Literal(0)),Literal(2))),Literal(3)),
    Pair(Pair(Pair(Pair(Literal(1),Literal(5)),Literal(3)),Pair(Pair(Literal(5),Literal(3)),Pair(Literal(5),Literal(4)))),Pair(Pair(Literal(0),Literal(1)),Pair(Pair(Literal(1),Literal(2)),Literal(8)))),
    Pair(Pair(Pair(Literal(1),Literal(1)),Pair(Pair(Literal(9),Literal(3)),Literal(9))),Pair(Pair(Literal(9),Pair(Literal(6),Literal(5))),Pair(Literal(2),Literal(6)))),
    Pair(Pair(Pair(Literal(9),Literal(3)),Pair(Literal(6),Pair(Literal(1),Literal(5)))),Pair(Pair(Literal(3),Literal(8)),Pair(Pair(Literal(4),Literal(6)),Pair(Literal(8),Literal(0))))),
    Pair(Pair(Literal(3),Pair(Literal(6),Literal(7))),Pair(Pair(Literal(3),Literal(0)),Pair(Literal(5),Pair(Literal(3),Literal(4))))),
    Pair(Literal(1),Pair(Literal(2),Pair(Pair(Literal(4),Literal(1)),Pair(Literal(2),Literal(3))))),
    Pair(Pair(Literal(6),Pair(Literal(7),Literal(8))),Pair(Pair(Literal(0),Pair(Literal(0),Literal(3))),Pair(Literal(6),Literal(7)))),
    Pair(Pair(Literal(8),Pair(Pair(Literal(0),Literal(0)),Pair(Literal(9),Literal(3)))),Pair(Pair(Literal(2),Literal(6)),Pair(Pair(Literal(9),Literal(1)),Pair(Literal(4),Literal(9))))),
    Pair(Pair(Literal(3),Literal(0)),Pair(Pair(Literal(8),Pair(Literal(7),Literal(1))),Literal(4))),
    Pair(Pair(Pair(Literal(1),Literal(0)),Pair(Pair(Literal(9),Literal(7)),Pair(Literal(7),Literal(8)))),Pair(Pair(Pair(Literal(0),Literal(0)),Literal(5)),Pair(Pair(Literal(4),Literal(9)),Literal(4)))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(2)),Literal(7)),Pair(Pair(Literal(4),Literal(0)),Literal(0))),Pair(Pair(Pair(Literal(5),Literal(4)),Pair(Literal(6),Literal(7))),Pair(Literal(0),Pair(Literal(1),Literal(2))))),
    Pair(Pair(Pair(Literal(4),Pair(Literal(4),Literal(3))),Pair(Pair(Literal(1),Literal(4)),Pair(Literal(1),Literal(1)))),Literal(6)),
    Pair(Pair(Pair(Literal(0),Pair(Literal(5),Literal(9))),Pair(Pair(Literal(7),Literal(4)),Literal(2))),Pair(Pair(Literal(9),Literal(1)),Pair(Literal(4),Literal(7)))),
    Pair(Pair(Pair(Pair(Literal(5),Literal(5)),Pair(Literal(7),Literal(0))),Pair(Literal(8),Pair(Literal(5),Literal(3)))),Pair(Pair(Literal(0),Pair(Literal(0),Literal(2))),Pair(Pair(Literal(1),Literal(3)),Pair(Literal(5),Literal(8))))),
    Pair(Pair(Literal(9),Pair(Pair(Literal(9),Literal(9)),Literal(2))),Pair(Pair(Literal(9),Literal(6)),Pair(Pair(Literal(4),Literal(7)),Literal(5)))),
    Pair(Pair(Pair(Pair(Literal(8),Literal(7)),Pair(Literal(5),Literal(3))),Literal(9)),Pair(Literal(3),Pair(Literal(6),Literal(9)))),
    Pair(Pair(Literal(3),Pair(Literal(0),Literal(3))),Pair(Literal(2),Literal(6))),
    Pair(Pair(Pair(Literal(2),Pair(Literal(7),Literal(0))),Pair(Literal(6),Literal(6))),Pair(Pair(Literal(7),Literal(0)),Pair(Pair(Literal(3),Literal(8)),Pair(Literal(8),Literal(5))))),
    Pair(Pair(Pair(Literal(2),Literal(6)),Pair(Literal(2),Literal(7))),Pair(Pair(Literal(3),Literal(6)),Pair(Literal(0),Pair(Literal(9),Literal(5))))),
    Pair(Pair(Pair(Literal(5),Literal(4)),Literal(1)),Pair(Literal(5),Pair(Pair(Literal(4),Literal(9)),Literal(5)))),
    Pair(Pair(Pair(Literal(6),Literal(3)),Literal(6)),Pair(Pair(Pair(Literal(6),Literal(0)),Literal(0)),Pair(Pair(Literal(4),Literal(0)),Literal(7)))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(1)),Literal(2)),Pair(Literal(3),Pair(Literal(9),Literal(0)))),Pair(Literal(0),Literal(8))),
    Pair(Pair(Pair(Literal(2),Pair(Literal(3),Literal(9))),Pair(Pair(Literal(8),Literal(3)),Literal(8))),Pair(Pair(Literal(1),Pair(Literal(2),Literal(2))),Pair(Literal(8),Pair(Literal(6),Literal(4))))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(3)),Pair(Literal(5),Literal(2))),Literal(0)),Pair(Literal(9),Pair(Literal(5),Pair(Literal(7),Literal(5))))),
    Pair(Pair(Pair(Literal(3),Literal(2)),Literal(5)),Pair(Pair(Pair(Literal(6),Literal(3)),Literal(9)),Pair(Pair(Literal(2),Literal(0)),Pair(Literal(6),Literal(7))))),
    Pair(Pair(Pair(Literal(3),Literal(9)),Pair(Pair(Literal(0),Literal(6)),Pair(Literal(0),Literal(7)))),Pair(Literal(6),Pair(Literal(3),Literal(2)))),
    Pair(Literal(0),Literal(0)),
    Pair(Pair(Pair(Pair(Literal(0),Literal(3)),Literal(9)),Pair(Literal(8),Pair(Literal(3),Literal(9)))),Pair(Pair(Literal(0),Literal(2)),Pair(Pair(Literal(0),Literal(1)),Pair(Literal(3),Literal(7))))),
    Pair(Pair(Literal(0),Pair(Literal(4),Pair(Literal(3),Literal(0)))),Pair(Pair(Literal(7),Literal(9)),Pair(Literal(5),Pair(Literal(8),Literal(7))))),
    Pair(Pair(Literal(2),Literal(9)),Pair(Pair(Literal(0),Pair(Literal(2),Literal(2))),Literal(1))),
    Pair(Pair(Pair(Pair(Literal(5),Literal(4)),Pair(Literal(1),Literal(7))),Literal(6)),Pair(Literal(2),Pair(Pair(Literal(5),Literal(3)),Pair(Literal(7),Literal(7))))),
    Pair(Pair(Pair(Pair(Literal(0),Literal(4)),Literal(4)),Pair(Pair(Literal(6),Literal(6)),Pair(Literal(1),Literal(4)))),Literal(4)),
    Pair(Pair(Pair(Pair(Literal(4),Literal(8)),Literal(5)),Pair(Pair(Literal(6),Literal(4)),Pair(Literal(2),Literal(3)))),Pair(Literal(9),Pair(Pair(Literal(8),Literal(6)),Pair(Literal(4),Literal(0))))),
    Pair(Pair(Literal(1),Pair(Literal(6),Pair(Literal(1),Literal(9)))),Pair(Literal(3),Pair(Pair(Literal(4),Literal(2)),Pair(Literal(1),Literal(8))))),
    Pair(Pair(Pair(Pair(Literal(3),Literal(7)),Pair(Literal(5),Literal(9))),Pair(Pair(Literal(3),Literal(8)),Pair(Literal(3),Literal(3)))),Pair(Pair(Pair(Literal(7),Literal(8)),Literal(3)),Pair(Literal(7),Literal(3)))),
    Pair(Pair(Pair(Pair(Literal(0),Literal(4)),Literal(5)),Pair(Literal(4),Pair(Literal(9),Literal(0)))),Pair(Literal(3),Pair(Pair(Literal(4),Literal(1)),Literal(6)))),
    Pair(Pair(Pair(Literal(7),Pair(Literal(2),Literal(1))),Pair(Pair(Literal(1),Literal(9)),Literal(1))),Pair(Pair(Pair(Literal(3),Literal(4)),Pair(Literal(8),Literal(6))),Literal(6))),
    Pair(Pair(Pair(Literal(4),Literal(1)),Pair(Literal(5),Pair(Literal(8),Literal(2)))),Pair(Pair(Pair(Literal(1),Literal(6)),Literal(9)),Pair(Pair(Literal(4),Literal(4)),Literal(2)))),
    Pair(Pair(Pair(Literal(7),Pair(Literal(6),Literal(4))),Pair(Pair(Literal(0),Literal(1)),Literal(4))),Pair(Pair(Literal(5),Literal(2)),Pair(Pair(Literal(9),Literal(5)),Pair(Literal(9),Literal(3))))),
    Pair(Pair(Pair(Literal(4),Literal(2)),Pair(Literal(1),Literal(8))),Literal(2)),
    Pair(Pair(Pair(Literal(1),Literal(6)),Literal(5)),Pair(Literal(8),Pair(Literal(2),Pair(Literal(2),Literal(3))))),
    Pair(Pair(Pair(Pair(Literal(0),Literal(2)),Pair(Literal(5),Literal(0))),Pair(Literal(7),Pair(Literal(0),Literal(0)))),Pair(Pair(Literal(6),Pair(Literal(5),Literal(9))),Literal(5))),
    Pair(Pair(Pair(Literal(7),Literal(6)),Pair(Literal(9),Pair(Literal(2),Literal(4)))),Pair(Pair(Literal(5),Pair(Literal(2),Literal(6))),Literal(2))),
    Pair(Pair(Pair(Literal(6),Literal(2)),Literal(4)),Pair(Pair(Literal(2),Literal(9)),Pair(Pair(Literal(3),Literal(0)),Pair(Literal(4),Literal(3))))),
    Pair(Pair(Literal(8),Pair(Pair(Literal(6),Literal(4)),Pair(Literal(0),Literal(2)))),Literal(1)),
    Pair(Pair(Pair(Literal(4),Literal(1)),Pair(Literal(7),Literal(5))),Pair(Literal(9),Pair(Pair(Literal(2),Literal(4)),Literal(4)))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(8)),Pair(Literal(7),Literal(5))),Pair(Literal(1),Pair(Literal(8),Literal(5)))),Pair(Pair(Literal(3),Literal(5)),Pair(Pair(Literal(9),Literal(9)),Pair(Literal(4),Literal(2))))),
    Pair(Pair(Pair(Literal(7),Pair(Literal(8),Literal(4))),Pair(Literal(4),Pair(Literal(5),Literal(8)))),Literal(5)),
    Pair(Pair(Literal(7),Literal(9)),Pair(Literal(2),Pair(Pair(Literal(9),Literal(1)),Pair(Literal(7),Literal(1))))),
    Pair(Literal(3),Pair(Pair(Pair(Literal(5),Literal(8)),Pair(Literal(4),Literal(8))),Pair(Literal(5),Literal(4)))),
    Pair(Pair(Pair(Literal(0),Pair(Literal(5),Literal(5))),Pair(Pair(Literal(5),Literal(4)),Pair(Literal(5),Literal(4)))),Pair(Pair(Literal(9),Literal(6)),Pair(Pair(Literal(9),Literal(4)),Pair(Literal(6),Literal(5))))),
    Pair(Pair(Literal(7),Literal(2)),Pair(Literal(1),Pair(Literal(8),Pair(Literal(1),Literal(7))))),
    Pair(Literal(2),Pair(Literal(9),Pair(Literal(2),Pair(Literal(2),Literal(3))))),
    Pair(Pair(Pair(Literal(3),Pair(Literal(5),Literal(1))),Pair(Literal(8),Pair(Literal(6),Literal(4)))),Pair(Pair(Literal(2),Literal(8)),Pair(Pair(Literal(2),Literal(2)),Literal(8)))),
    Pair(Pair(Pair(Literal(7),Literal(3)),Pair(Literal(0),Literal(4))),Pair(Pair(Literal(4),Literal(0)),Pair(Literal(6),Pair(Literal(3),Literal(4))))),
    Pair(Pair(Literal(4),Pair(Literal(2),Pair(Literal(2),Literal(8)))),Pair(Literal(4),Pair(Pair(Literal(7),Literal(1)),Literal(9)))),
    Pair(Pair(Literal(8),Pair(Pair(Literal(6),Literal(1)),Literal(2))),Pair(Literal(1),Pair(Pair(Literal(1),Literal(5)),Literal(9)))),
    Pair(Pair(Literal(0),Pair(Literal(2),Pair(Literal(9),Literal(4)))),Pair(Pair(Pair(Literal(7),Literal(4)),Literal(7)),Literal(8))),
    Pair(Pair(Pair(Literal(2),Pair(Literal(7),Literal(0))),Literal(5)),Pair(Literal(3),Pair(Literal(4),Literal(4)))),
    Pair(Pair(Literal(7),Pair(Literal(4),Pair(Literal(6),Literal(0)))),Pair(Pair(Literal(4),Literal(7)),Pair(Pair(Literal(3),Literal(7)),Literal(5)))),
    Pair(Pair(Literal(2),Pair(Pair(Literal(8),Literal(0)),Pair(Literal(6),Literal(1)))),Pair(Pair(Literal(6),Pair(Literal(6),Literal(1))),Pair(Literal(3),Literal(9)))),
    Pair(Pair(Literal(9),Literal(0)),Pair(Pair(Pair(Literal(3),Literal(7)),Literal(0)),Pair(Pair(Literal(5),Literal(8)),Literal(4)))),
    Pair(Literal(6),Pair(Pair(Pair(Literal(5),Literal(8)),Literal(8)),Pair(Literal(3),Pair(Literal(4),Literal(1))))),
    Pair(Pair(Literal(8),Pair(Pair(Literal(9),Literal(3)),Pair(Literal(8),Literal(4)))),Pair(Literal(4),Pair(Literal(8),Literal(2)))),
    Pair(Pair(Pair(Pair(Literal(8),Literal(0)),Literal(8)),Pair(Literal(3),Literal(7))),Pair(Pair(Literal(7),Pair(Literal(4),Literal(3))),Literal(0))),
    Pair(Pair(Pair(Literal(7),Pair(Literal(2),Literal(6))),Pair(Literal(8),Literal(0))),Pair(Literal(4),Pair(Pair(Literal(1),Literal(3)),Pair(Literal(4),Literal(1))))),
    Pair(Literal(1),Pair(Pair(Pair(Literal(4),Literal(9)),Pair(Literal(4),Literal(9))),Pair(Pair(Literal(7),Literal(0)),Pair(Literal(6),Literal(6))))),
    Pair(Literal(9),Literal(4)),
    Pair(Pair(Literal(6),Literal(7)),Literal(4)),
    Pair(Pair(Literal(2),Pair(Literal(5),Literal(2))),Pair(Pair(Literal(2),Literal(4)),Pair(Pair(Literal(4),Literal(6)),Pair(Literal(5),Literal(5))))),
    Pair(Pair(Pair(Literal(5),Literal(2)),Pair(Pair(Literal(5),Literal(5)),Pair(Literal(8),Literal(1)))),Pair(Pair(Literal(9),Pair(Literal(1),Literal(6))),Literal(3))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(3)),Literal(1)),Pair(Literal(8),Literal(9))),Literal(6)),
    Pair(Pair(Pair(Pair(Literal(3),Literal(2)),Pair(Literal(4),Literal(5))),Literal(4)),Pair(Pair(Pair(Literal(4),Literal(3)),Pair(Literal(0),Literal(0))),Pair(Pair(Literal(3),Literal(0)),Literal(1)))),
    Pair(Pair(Literal(6),Literal(7)),Pair(Pair(Literal(8),Literal(5)),Pair(Pair(Literal(7),Literal(2)),Literal(4)))),
    Pair(Pair(Pair(Pair(Literal(8),Literal(1)),Pair(Literal(5),Literal(8))),Literal(7)),Pair(Pair(Pair(Literal(5),Literal(2)),Pair(Literal(4),Literal(3))),Literal(1))),
    Pair(Pair(Literal(2),Pair(Pair(Literal(4),Literal(9)),Literal(5))),Pair(Literal(1),Literal(1))),
    Pair(Pair(Literal(9),Literal(1)),Pair(Pair(Pair(Literal(0),Literal(8)),Pair(Literal(1),Literal(8))),Literal(7))),
    Pair(Pair(Literal(9),Literal(3)),Pair(Literal(6),Literal(4))),
    Pair(Pair(Literal(8),Pair(Literal(4),Literal(2))),Pair(Pair(Literal(7),Pair(Literal(7),Literal(4))),Pair(Pair(Literal(0),Literal(9)),Pair(Literal(6),Literal(1))))),
    Pair(Pair(Pair(Pair(Literal(0),Literal(5)),Literal(7)),Pair(Pair(Literal(7),Literal(7)),Literal(2))),Pair(Pair(Literal(2),Pair(Literal(5),Literal(8))),Pair(Literal(9),Literal(6)))),
    Pair(Pair(Pair(Literal(2),Literal(1)),Pair(Literal(7),Pair(Literal(1),Literal(3)))),Pair(Pair(Literal(2),Pair(Literal(7),Literal(1))),Literal(0))),
    Pair(Pair(Pair(Literal(8),Pair(Literal(8),Literal(4))),Pair(Literal(2),Pair(Literal(4),Literal(3)))),Pair(Pair(Literal(2),Pair(Literal(5),Literal(6))),Pair(Pair(Literal(2),Literal(0)),Pair(Literal(7),Literal(3))))),
    Pair(Pair(Literal(4),Pair(Pair(Literal(4),Literal(3)),Pair(Literal(5),Literal(2)))),Pair(Literal(1),Literal(3))),
    Pair(Pair(Literal(5),Pair(Literal(5),Literal(0))),Literal(9)),
    Pair(Pair(Pair(Literal(2),Pair(Literal(7),Literal(6))),Pair(Literal(1),Literal(8))),Pair(Pair(Pair(Literal(5),Literal(2)),Literal(2)),Literal(0))),
    Pair(Pair(Literal(2),Pair(Literal(2),Literal(3))),Pair(Pair(Literal(9),Literal(8)),Pair(Pair(Literal(0),Literal(1)),Pair(Literal(3),Literal(5))))),
    Pair(Pair(Literal(7),Pair(Pair(Literal(3),Literal(7)),Literal(3))),Pair(Pair(Pair(Literal(7),Literal(6)),Pair(Literal(4),Literal(8))),Pair(Pair(Literal(1),Literal(7)),Pair(Literal(8),Literal(6))))),
    Pair(Pair(Pair(Literal(0),Literal(0)),Pair(Pair(Literal(6),Literal(1)),Literal(5))),Pair(Literal(5),Pair(Literal(5),Literal(4)))),
    Pair(Pair(Literal(2),Literal(3)),Pair(Literal(4),Pair(Literal(3),Literal(5)))),
    Pair(Pair(Literal(8),Pair(Literal(7),Literal(7))),Pair(Literal(8),Pair(Literal(4),Pair(Literal(8),Literal(1))))),
    Pair(Pair(Pair(Pair(Literal(4),Literal(0)),Literal(3)),Pair(Pair(Literal(0),Literal(0)),Pair(Literal(0),Literal(0)))),Pair(Pair(Pair(Literal(6),Literal(0)),Literal(4)),Pair(Pair(Literal(1),Literal(7)),Literal(0)))),
    Pair(Pair(Pair(Pair(Literal(6),Literal(4)),Pair(Literal(3),Literal(1))),Pair(Pair(Literal(2),Literal(8)),Pair(Literal(1),Literal(2)))),Pair(Literal(4),Pair(Pair(Literal(6),Literal(5)),Literal(4)))),
    Pair(Pair(Pair(Pair(Literal(5),Literal(3)),Literal(7)),Pair(Literal(4),Pair(Literal(2),Literal(6)))),Pair(Pair(Literal(6),Pair(Literal(4),Literal(5))),Pair(Literal(1),Pair(Literal(9),Literal(0)))))
  ]
}
