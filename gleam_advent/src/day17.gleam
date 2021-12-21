import utils
import gleam/string
import gleam/iterator
import gleam/result
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day17.txt")
  data |> string.trim()
}

type Input {
  Input(x_start: Int, x_finish: Int, y_start: Int, y_finish: Int)
}

fn parse(input: String) {
  assert [#(x_start, x_finish), #(y_start, y_finish)] = input
    |> string.replace("target area: x=", "")
    |> string.split(", y=")
    |> list.map(assert_to_range)

  Input(x_start, x_finish, y_start, y_finish)
}

fn assert_to_range(input: String) {
  let [start, finish] = input |> string.split("..") |> list.map(utils.assert_parse_int)
  #(start, finish)
}

fn calc_part_1(data) {
  let input = data |> parse()
  assert Ok(y_velocity) = count_from(1)
  |> iterator.take_while(fn(x_velocity) {
    x_velocity <= input.x_finish
  })
  |> iterator.map(fn(x_velocity) {
    find_y_velocity(x_velocity, input)
    |> iterator.to_list()
    |> list.last()
  })
  |> iterator.filter(result.is_ok)
  |> iterator.to_list()
  |> result.values()
  |> list.reduce(int.max)

  find_max_height(y_velocity)
}

fn find_max_height(y_velocity) {
  list.range(0, y_velocity + 1) |> int.sum()
}

fn count_from(start) {
  iterator.unfold(start - 1, fn(acc) {
    iterator.Next(acc + 1, acc + 1)
  })
}

fn position_in_range(value: Int, lower_bound: Int, upper_bound: Int) -> Bool {
  value >= lower_bound && value <= upper_bound
}

fn find_y_velocity(x_velocity: Int, input: Input) {
  count_from(input.y_start)
  |> iterator.map(fn(y_velocity) {
    let could_possibly_overlap_later = fn(data) {
      let #(velocity, position) = data
      let #(_, y_velocity) = velocity
      let #(_, y_position) = position
      y_velocity > 0 || y_position >= input.y_start
    }
    let did_actually_overlap = fn(data) {
      let #(_, position) = data
      let #(x_position, y_position) = position
      position_in_range(x_position, input.x_start, input.x_finish)
        && position_in_range(y_position, input.y_start, input.y_finish)
    }
    let no_x_overlap = fn(data) {
      let #(_, position) = data
      let #(x_position, _y_position) = position
      x_position < input.x_start
    }
    let going_forward = fn(data) {
      let #(velocity, _position) = data
      let #(x_velocity, _) = velocity
      x_velocity > 0
    }

    let positions = count_from(1)
    |> iterator.scan(#(#(x_velocity, y_velocity), #(0, 0)), fn(data, _) {
      let #(velocity, position) = data
      step(velocity, position)
    })

    let overlapped = positions
      |> iterator.take_while(could_possibly_overlap_later)
      |> iterator.any(did_actually_overlap)

    let overshot = y_velocity > 200
    // no idea how to get rid of this magic number.  I thought of a bunch of
    // algorithms but they didn't work!

    let undershot = positions
      |> iterator.take_while(going_forward)
      |> iterator.all(no_x_overlap)

    #(y_velocity, overshot || undershot, overlapped)
  })
  |> iterator.take_while(fn(data) {
    let #(_, done, _) = data
    done |> bool.negate()
  })
  |> iterator.filter(fn(data) {
    let #(_, _, overlapped) = data
    overlapped
  })
  |> iterator.map(fn(data) {
    let #(y_velocity, _, _) = data
    y_velocity
  })
}

fn step(velocity, position) {
  let #(x, y) = position
  let #(x_velocity, y_velocity) = velocity
  let new_x = x + x_velocity
  let new_y = y + y_velocity
  let new_x_velocity = int.max(x_velocity - 1, 0)
  let new_y_velocity = y_velocity - 1
  #(#(new_x_velocity, new_y_velocity), #(new_x, new_y))
}

fn calc_part_2(data) {
  let input = data |> parse()
  count_from(1)
  |> iterator.take_while(fn(x_velocity) {
    x_velocity <= input.x_finish
  })
  |> iterator.flat_map(fn(x_velocity) {
    find_y_velocity(x_velocity, input)
    |> iterator.map(fn(y_velocity) {
      #(x_velocity, y_velocity)
    })
  })
  |> iterator.to_list()
  |> list.length()
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
