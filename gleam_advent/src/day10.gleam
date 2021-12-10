import utils
import gleam/string
import gleam/bool
import gleam/pair
import gleam/float
import gleam/result
import gleam/set
import gleam/map
import gleam/int
import gleam/list

type Char {
  OpenSquare
  CloseSquare
  OpenParen
  CloseParen
  OpenSquiggle
  CloseSquiggle
  OpenTriangle
  CloseTriangle
}

type ParseError {
  UnexpectedEndOfInput
  UnexpectedEndOfBlock(block_type: BlockType)
  UnexpectedChar(char: Char)
}

type Block {
  Block(block_type: BlockType, inner: List(Block))
}

type BlockType {
  Paren
  Square
  Squiggle
  Triangle
}



fn input() {
  assert Ok(data) = utils.read_file("input_day10.txt")
  data |> string.trim()
}

fn parse(input: String) -> List(List(Char)) {
  input
  |> string.split("\n")
  |> list.map(parse_row)
}

fn parse_row(input: String) -> List(Char) {
  input
  |> string.to_graphemes()
  |> list.map(assert_parse_char)
}

fn assert_parse_char(char: String) -> Char {
  case char {
    "{" -> OpenSquiggle
    "}" -> CloseSquiggle
    "[" -> OpenSquare
    "]" -> CloseSquare
    "(" -> OpenParen
    ")" -> CloseParen
    "<" -> OpenTriangle
    ">" -> CloseTriangle
  }
}

fn actual_parse(line) {
  case consume_block(line) {
    Ok(data) -> {
      let #(block, rest) = data
      case rest {
        [] -> Ok([block])
        other ->
          actual_parse(rest)
          |> result.map(fn(other) {
            list.append([block], other)
          })
      }
    }

    Error(x) -> Error(x)
  }
}

fn consume_block(chars: List(Char)) -> Result(#(Block, List(Char)), ParseError) {
  case chars {
    [] -> Error(UnexpectedEndOfInput)
    [OpenParen, ..rest] -> finish_consume_block(rest, Paren, CloseParen)
    [OpenSquare, ..rest] -> finish_consume_block(rest, Square, CloseSquare)
    [OpenSquiggle, ..rest] -> finish_consume_block(rest, Squiggle, CloseSquiggle)
    [OpenTriangle, ..rest] -> finish_consume_block(rest, Triangle, CloseTriangle)
  }
}

fn finish_consume_block(chars: List(Char), block_type: BlockType, until: Char) -> Result(#(Block, List(Char)), ParseError) {
  case chars {
    [] -> Error(UnexpectedEndOfBlock(block_type))
    [char, ..rest] if char == until -> Ok(#(Block(block_type: block_type, inner: []), rest))
    [char, ..rest] -> {
      case char {
        CloseParen -> Error(UnexpectedChar(CloseParen))
        CloseSquare -> Error(UnexpectedChar(CloseSquare))
        CloseSquiggle -> Error(UnexpectedChar(CloseSquiggle))
        CloseTriangle -> Error(UnexpectedChar(CloseTriangle))
        _other ->
          consume_block(chars)
          |> result.then(fn(res) {
            let #(block, rest) = res
            finish_consume_block(rest, block_type, until)
            |> result.map(fn(data: #(Block, List(Char))) {
              let #(rest_of_block, rest) = data
              let full_block = Block(block_type: block_type, inner: list.append([block], rest_of_block.inner))
              #(full_block, rest)
            })
          })
      }
    }
  }
}

fn calc_part_1(data) {
  data
  |> parse()
  |> list.map(actual_parse)
  |> list.filter_map(fn(val) {
    case val {
      Error(UnexpectedChar(char)) -> Ok(char)
      _other -> Error(Nil)
    }
  })
  |> list.map(score)
  |> list.fold(0, fn(a, b) { a + b })
}

fn score(char: Char) {
  case char {
    CloseParen -> 3
    CloseSquare -> 57
    CloseSquiggle -> 1197
    CloseTriangle -> 25137
  }
}

fn score_part_2(chars: List(Char), score: Int) -> Int {
  case actual_parse(chars) {
    Error(UnexpectedEndOfBlock(block_type)) ->
      score_part_2(list.append(chars, [end_block_char(block_type)]), score * 5 + score_of(block_type))
    Ok(_) -> score
  }
}

fn end_block_char(block_type: BlockType) {
  case block_type {
    Paren -> CloseParen
    Square -> CloseSquare
    Squiggle -> CloseSquiggle
    Triangle -> CloseTriangle
  }
}

fn score_of(block_type: BlockType) {
  case block_type {
    Paren -> 1
    Square -> 2
    Squiggle -> 3
    Triangle -> 4
  }
}

fn calc_part_2(data) {
  let scores = data
  |> parse()
  |> list.filter(fn(line) {
    case actual_parse(line) {
      Error(UnexpectedEndOfBlock(_)) -> True
      _other -> False
    }
  })
  |> list.map(score_part_2(_, 0))
  |> list.sort(int.compare)

  midpoint(scores)
}

fn midpoint(input) {
  let tmp = input
    |> list.length()
    |> int.to_float()

  let midpoint = tmp /. 2.0
    |> float.truncate()

  list.at(input, midpoint)
}

pub fn part1() {
  assert Error(UnexpectedChar(CloseParen)) = { "[[<[([]))<([[{}[[()]]]" } |> parse_row() |> actual_parse()
  assert Error(UnexpectedChar(CloseSquare)) = { "[{[{({}]{}}([{[{{{}}([]" } |> parse_row() |> actual_parse()
  assert Error(UnexpectedChar(CloseParen)) = { "[<(<(<(<{}))><([]([]()" } |> parse_row() |> actual_parse()
  assert Error(UnexpectedChar(CloseTriangle)) = { "<{([([[(<>()){}]>(<<{{" } |> parse_row() |> actual_parse()
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
