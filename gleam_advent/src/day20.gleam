import utils
import gleam/string
import gleam/result
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day20.txt")
  data |> string.trim()
}

fn example() {
  assert Ok(data) = utils.read_file("example_day20.txt")
  data |> string.trim()
}

type Pixel {
  Light
  Dark
}

type Position {
  Position(x: Int, y: Int)
}

type Input {
  Input(
    algorithm: map.Map(Int, Pixel),
    img: map.Map(Position, Pixel)
  )
}

fn pixel_from_char(value: String) -> Pixel {
  case value {
    "#" -> Light
    "." -> Dark
  }
}

fn parse(input: String) {
  assert [algorithm_string, lines] = input
  |> string.split("\n\n")

  let algorithm = algorithm_string
  |> string.to_graphemes()
  |> list.index_map(fn(index, value) {
    #(index, pixel_from_char(value))
  })
  |> map.from_list()

  let img = lines
  |> string.split("\n")
  |> list.index_map(fn(y, line) {
    line
    |> string.to_graphemes()
    |> list.index_map(fn(x, char) {
      #(Position(x, y), pixel_from_char(char))
    })
  })
  |> list.flatten()
  |> map.from_list()

  Input(algorithm: algorithm, img: img)
}

fn min_max(input: List(Int)) -> Result(#(Int, Int), Nil) {
  let sorted = input |> list.sort(int.compare)

  let first = list.first(sorted)
  let last = list.last(sorted)

  result.all([first, last])
  |> result.map(fn(vals) {
    assert [min, max] = vals
    #(min, max)
  })
}

fn enhance(input: Input, default: Pixel) -> Input {
  let positions = input.img
  |> map.to_list()
  |> list.map(pair.first)

  assert Ok(#(min_x, max_x)) = positions
  |> list.map(fn(p: Position) { p.x })
  |> min_max()

  assert Ok(#(min_y, max_y)) = positions
  |> list.map(fn(p: Position) { p.y })
  |> min_max()

  let positions: List(Position) = list.range(min_x - 1, max_x - min_x + 3)
  |> list.flat_map(fn(x) {
    list.range(min_y - 1, max_y - min_y + 3)
    |> list.map(fn(y) {
      Position(x, y)
    })
  })

  let new_img = positions
  |> list.map(fn(position: Position) {
    let Position(x, y) = position

    assert Ok(pixel) = [
      Position(x - 1, y - 1),
      Position(x, y - 1),
      Position(x + 1, y - 1),
      Position(x - 1, y),
      Position(x, y),
      Position(x + 1, y),
      Position(x - 1, y + 1),
      Position(x, y + 1),
      Position(x + 1, y + 1)
    ]
    |> list.map(fn(position) {
      let pixel = position
      |> map.get(input.img, _)
      |> result.unwrap(default)

      case pixel {
        Dark -> "0"
        Light -> "1"
      }
    })
    |> string.join("")
    |> utils.binary_to_int()
    |> map.get(input.algorithm, _)

    #(position, pixel)
  })
  |> map.from_list()

  Input(..input, img: new_img)
}

fn double_enhance(data: Input) {
  let toggles_the_infinite_grid = data.algorithm |> map.get(0) == Ok(Light)
  let second_enhance_default = case toggles_the_infinite_grid {
    True -> Light
    False -> Dark
  }
  data
  |> enhance(Dark)
  |> enhance(second_enhance_default)
}

fn calc_part_1(data) {
  let final_data = data
  |> parse()
  |> double_enhance()

  final_data.img
  |> map.to_list()
  |> list.filter(fn(x) {
    let #(_, val) = x
    val == Light
  })
  |> list.length()
}

fn calc_part_2(data) {
  let data = data |> parse()

  let final_data = list.range(0, 25)
  |> list.fold(data, fn(data, i) {
    utils.inspect(i * 2)

    double_enhance(data)
  })

  final_data.img
  |> map.to_list()
  |> list.filter(fn(x) {
    let #(_, val) = x
    val == Light
  })
  |> list.length()
}

pub fn part1() {
  assert 35 = calc_part_1(example())
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
