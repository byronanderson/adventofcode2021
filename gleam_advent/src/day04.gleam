import utils
import gleam/string
import gleam/result
import gleam/bool
import gleam/list
import gleam/map
import gleam/regex
import gleam/int
import gleam/set
import gleam/iterator
import gleam/order

fn input() {
  assert Ok(data) = utils.read_file("input_day04.txt")
  data
  |> string.trim()
  |> parse()
}

type Row = #(Int, Int, Int, Int, Int)
type Board = #(Row, Row, Row, Row, Row)

type Input {
  Input(boards: List(Board), number_calling_order: List(Int))
}

fn parse(input: String) {
  assert [number_calling_order, ..boards] = input |> string.split("\n\n")

  let number_calling_order = number_calling_order
    |> string.split(",")
    |> list.map(assert_parse_int)

  let boards = boards |> list.map(parse_board)

  Input(boards: boards, number_calling_order: number_calling_order)
}

fn parse_board(board: String) -> Board {
  assert [row1, row2, row3, row4, row5] = board
    |> string.split("\n")
    |> list.map(parse_row)

  #(row1, row2, row3, row4, row5)
}

fn parse_row(row: String) -> Row {
  assert Ok(re) = regex.from_string(" +")
  assert [val1, val2, val3, val4, val5] = row
    |> string.trim()
    |> regex.split(re, _)
    |> list.map(assert_parse_int)

  #(val1, val2, val3, val4, val5)
}

fn assert_parse_int(input: String) -> Int {
  assert Ok(data) = int.parse(input)
  data
}

fn board_won(board: Board, called_numbers: set.Set(Int)) {
  let called = fn(value: Int) {
    called_numbers |> set.contains(value)
  }
  let all_column_called = fn(row_fn) {
    called(row_fn(board.0))
    && called(row_fn(board.1))
    && called(row_fn(board.2))
    && called(row_fn(board.3))
    && called(row_fn(board.4))
  }

  let all_row_called = fn(row: Row) {
    called(row.0)
    && called(row.1)
    && called(row.2)
    && called(row.3)
    && called(row.4)
  }

  let all_called = fn(values: List(Int)) {
    list.all(values, called)
  }
  all_column_called(fn(row: Row) { row.0 })
  || all_column_called(fn(row: Row) { row.1 })
  || all_column_called(fn(row: Row) { row.2 })
  || all_column_called(fn(row: Row) { row.3 })
  || all_column_called(fn(row: Row) { row.4 })
  || all_row_called(board.0)
  || all_row_called(board.1)
  || all_row_called(board.2)
  || all_row_called(board.3)
  || all_row_called(board.4)
  || all_called([{ board.0 }.0, { board.1 }.1, { board.2 }.2, { board.3 }.3, { board.4 }.4])
  || all_called([{ board.0 }.4, { board.1 }.3, { board.2 }.2, { board.3 }.1, { board.4 }.0])
}

fn calc_part_1(input: Input) {
  iterator.unfold(#(set.new(), input.number_calling_order), fn(acc) {
    let #(called_values, number_calling_order) = acc
    case number_calling_order {
      [] -> iterator.Done
      [first, ..rest] -> {
        let new_set = set.insert(called_values, first)
        iterator.Next(element: #(new_set, first), accumulator: #(new_set, rest))
      }
    }
  })
  |> iterator.map(fn(el) {
    let #(called_numbers, just_called_number) = el
    #(list.find(input.boards, board_won(_, called_numbers)), just_called_number, called_numbers)
  })
  |> iterator.filter(fn(el) {
    let #(winner_board, _, _) = el
    case winner_board {
      Ok(_board) -> True
      Error(_) -> False
    }
  })
  |> iterator.map(fn(el) {
    let #(winner_board, just_called_number, called_numbers) = el
    assert Ok(board) = winner_board
    #(board, just_called_number, called_numbers)
  })
  |> iterator.first()
  |> result.map(fn(el) {
    let #(winner_board, just_called_number, called_numbers) = el
    let board_score = winner_board |> score(called_numbers)
    board_score * just_called_number
  })
}

fn values(board: Board) -> List(Int) {
  [
    { board.0 }.0,
    { board.1 }.0,
    { board.2 }.0,
    { board.3 }.0,
    { board.4 }.0,
    { board.0 }.1,
    { board.1 }.1,
    { board.2 }.1,
    { board.3 }.1,
    { board.4 }.1,
    { board.0 }.2,
    { board.1 }.2,
    { board.2 }.2,
    { board.3 }.2,
    { board.4 }.2,
    { board.0 }.3,
    { board.1 }.3,
    { board.2 }.3,
    { board.3 }.3,
    { board.4 }.3,
    { board.0 }.4,
    { board.1 }.4,
    { board.2 }.4,
    { board.3 }.4,
    { board.4 }.4
  ]
}

fn score(board: Board, called_numbers: set.Set(Int)) {
  values(board)
  |> list.filter(fn(value) {
    set.contains(called_numbers, value)
    |> bool.negate()
  })
  |> list.fold(0, fn(a, b) { a + b })
}

fn calc_part_2(input: Input) {
  iterator.unfold(#(set.new(), input.number_calling_order), fn(acc) {
    let #(called_values, number_calling_order) = acc
    case number_calling_order {
      [] -> iterator.Done
      [first, ..rest] -> {
        let new_set = set.insert(called_values, first)
        iterator.Next(element: new_set, accumulator: #(new_set, rest))
      }
    }
  })
  |> iterator.map(fn(called_numbers) {
    utils.group_by(input.boards, board_won(_, called_numbers))
  })
  |> iterator.map(fn(board_win_states) {
    case map.get(board_win_states, False) {
      Ok([board]) -> Ok(board)
      _other -> Error(Nil)
    }
  })
  |> iterator.filter(fn(result: Result(Board, Nil)) {
    case result {
      Ok(_) -> True
      _ -> False
    }
  })
  |> iterator.first()
  |> result.then(fn(result) {
    assert Ok(board) = result
    calc_part_1(Input(..input, boards: [board]))
  })
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}

