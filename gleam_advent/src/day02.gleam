import utils
import gleam/string
import gleam/list
import gleam/int

type Direction {
  Forward
  Up
  Down
}

type Movement {
  Movement(direction: Direction, amount: Int)
}

type Position {
  Position(depth: Int, horizontal: Int)
}

type Position2 {
  Position2(depth: Int, horizontal: Int, aim: Int)
}

fn input() {
  assert Ok(data) = utils.read_file("input_day02.txt")
  data |> string.trim()
}

fn parse(input: String) -> List(Movement) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) {
    assert [first, second] = string.split(line, " ")
    let direction = case first {
      "forward" -> Forward
      "up" -> Up
      "down" -> Down
    }
    assert Ok(amount) = int.parse(second)
    Movement(direction: direction, amount: amount)
  })
}

fn calc_part_1(data) {
  let result_position = data
  |> parse()
  |> list.fold(Position(horizontal: 0, depth: 0), fn(position: Position, movement: Movement) {
    case movement.direction {
      Forward -> Position(..position, horizontal: position.horizontal + movement.amount)
      Up -> Position(..position, depth: position.depth - movement.amount)
      Down -> Position(..position, depth: position.depth + movement.amount)
    }
  })

  result_position.horizontal * result_position.depth
}

fn calc_part_2(data) {
  let result_position = data
  |> parse()
  |> list.fold(Position2(horizontal: 0, depth: 0, aim: 0), fn(position: Position2, movement: Movement) {
    case movement.direction {
      Forward -> Position2(
        ..position,
        horizontal: position.horizontal + movement.amount,
        depth: movement.amount * position.aim + position.depth
      )
      Up -> Position2(..position, aim: position.aim - movement.amount)
      Down -> Position2(..position, aim: position.aim + movement.amount)
    }
  })

  result_position.horizontal * result_position.depth
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
