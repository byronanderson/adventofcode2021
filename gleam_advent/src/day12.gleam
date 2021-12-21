import utils
import gleam/string
import gleam/bool
import gleam/pair
import gleam/io
import gleam/set
import gleam/map
import gleam/int
import gleam/list
import gleam/order
import gleam/option
import gleam/result

type Cave {
  SmallCave(input: String)
  LargeCave(input: String)
}

fn input() {
  assert Ok(data) = utils.read_file("input_day12.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
  |> string.split("\n")
  |> list.map(parse_connection)
  |> list.flat_map(fn(connection) {
    let #(one, two) = connection
    [#(one, two), #(two, one)]
  })
  |> list.fold(map.new(), fn(acc, connection) {
    let #(one, two) = connection
    map.update(acc, one, fn(value) {
      case value {
        option.Some(list) -> [two, ..list]
        option.None -> [two]
      }
    })
  })
}

fn parse_connection(input: String) {
  assert [one, two] = string.split(input, "-") |> list.map(parse_node)
  #(one, two)
}

fn parse_node(input: String) {
  case string.compare(string.uppercase(input), input) {
    order.Eq -> LargeCave(input)
    _ -> SmallCave(input)
  }
}

fn find_paths(connections, hops, already_visited) {
  assert Ok(current_location) = list.last(hops)
  assert Ok(connected) = map.get(connections, current_location)

  connected
  |> list.filter(fn(location) {
    case location {
      LargeCave(_) -> True
      SmallCave(_) -> already_visited |> set.contains(location) |> bool.negate()
    }
  })
  |> list.flat_map(fn(connection) {
    find_paths(connections, list.append(hops, [connection]), set.insert(already_visited, current_location))
  })
  |> list.append([hops])
}

fn calc_part_1(data) {
  let connections = data |> parse()

  find_paths(connections, [SmallCave("start")], set.new())
  |> list.filter(fn(path) {
    assert Ok(destination) = list.last(path)
    destination == SmallCave("end")
  })
  |> list.length()
}

fn find_paths_2(connections, hops, already_visited) {
  assert Ok(current_location) = list.last(hops)
  assert Ok(connected) = map.get(connections, current_location)

  connected
  |> list.filter(fn(location) {
    case location {
      LargeCave(_) -> True
      SmallCave(_) -> {
        let visit_count = already_visited |> map.get(location) |> result.unwrap(0)
        visit_count < 1
      }
    }
  })
  |> list.flat_map(fn(connection) {
    find_paths_2(connections, list.append(hops, [connection]), increment_visits(already_visited, current_location))
  })
  |> list.append([hops])
}

fn increment_visits(already_visited: map.Map(Cave, Int), location: Cave) -> map.Map(Cave, Int) {
  map.update(already_visited, location, fn(value) {
    case value {
      option.Some(num) -> num + 1
      option.None -> 1
    }
  })
}

fn small_caves(data) {
  map.keys(data)
  |> list.filter(fn(cave: Cave) {
    case cave {
      SmallCave("end") -> False
      SmallCave("start") -> False
      LargeCave(_) -> False
      SmallCave(_) -> True
    }
  })
}

fn calc_part_2(data) {
  let connections = data |> parse()

  small_caves(connections)
  |> list.fold(set.new(), fn(acc, special_small_cave) {
    find_paths_2(
      connections,
      [SmallCave("start")],
      map.new() |> map.insert(SmallCave("start"), 1)
      |> map.insert(special_small_cave, -1)
    )
    |> list.filter(fn(path) {
      assert Ok(destination) = list.last(path)
      destination == SmallCave("end")
    })
    |> list.fold(acc, fn(acc, el) {
      set.insert(acc, el)
    })
  })
  |> set.size()
}

pub fn part1() {
  calc_part_1(input())
}

pub fn part2() {
  assert 36 = calc_part_2("start-A
start-b
A-c
A-b
b-d
A-end
b-end")
  calc_part_2(input())
}
