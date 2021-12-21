import utils
import gleam/string
import gleam/order
import gleam/result
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list
import priority_queue
import priority_queue.{PriorityQueue}

fn input() {
  assert Ok(data) = utils.read_file("input_day15.txt")
  data |> string.trim()
}

type Position = #(Int, Int)

type Input {
  Input(risks: map.Map(Position, Int), width: Int, height: Int)
}

fn parse(input: String) {
  let lines = input |> string.split("\n")

  let risks = lines
  |> list.index_map(fn(y, line) {
    line
    |> string.to_graphemes()
    |> list.index_map(fn(x, char) {
      #(#(x, y), utils.assert_parse_int(char))
    })
  })
  |> list.flatten()

  assert Ok(#(#(max_x, _), _)) = list.last(risks)

  Input(
    risks: map.from_list(risks),
    width: max_x + 1,
    height: list.length(lines)
  )
}

fn calc_part_1(data) {
  dijkstra_pathfind(data, #(0, 0), map.new() |> map.insert(#(0, 0), 0), priority_queue.new(), set.new())
  |> map.get(#(data.width - 1, data.height - 1))
  |> result.unwrap(-1)
}


// 685 vs 686?

fn neighbors(position: Position, data: Input) {
  let #(x, y) = position
  result.values([
    map.get(data.risks, #(x + 1, y)) |> result.map(fn(_) { #(x + 1, y) }),
    map.get(data.risks, #(x - 1, y)) |> result.map(fn(_) { #(x - 1, y) }),
    map.get(data.risks, #(x, y + 1)) |> result.map(fn(_) { #(x, y + 1) }),
    map.get(data.risks, #(x, y - 1)) |> result.map(fn(_) { #(x, y - 1) })
  ])
  |> set.from_list()
}

fn dijkstra_pathfind(data: Input, current_node: Position, distances: map.Map(Position, Int), queue: PriorityQueue(Position), visited: set.Set(Position)) {
  assert Ok(distance_to_current_node) = map.get(distances, current_node)
  let unvisited_neighbors = neighbors(current_node, data)
  |> set.filter(fn(x) { set.contains(visited, x) |> bool.negate() })

  let #(distances, queue) = unvisited_neighbors
  |> set.to_list()
  |> list.fold(#(distances, queue), fn(acc, neighbor) {
    let #(distances, queue) = acc
    assert Ok(risk) = map.get(data.risks, neighbor)
    let candidate_distance = distance_to_current_node + risk
    let distance = map.get(distances, neighbor) |> result.unwrap(10000000000)

    case int.compare(candidate_distance, distance) {
      order.Lt -> #(
        distances |> map.insert(neighbor, candidate_distance),
        queue |> priority_queue.insert(neighbor, candidate_distance)
      )
      _ -> #(distances, queue)
    }
  })

  let visited = visited |> set.insert(current_node)

  case priority_queue.pop(queue) {
    Ok(#(position, queue)) -> dijkstra_pathfind(data, position, distances, queue, visited)
    _ -> distances
  }
}

fn stitch_together_x(one: Input, two: Input) {
  let stitched_risks = two.risks
  |> map.to_list()
  |> list.map(fn(entry) {
    let #(#(x, y), value) = entry
    let new_x = one.width + x
    #(#(new_x, y), value)
  })
  |> map.from_list()
  |> map.merge(one.risks)

  case one.height == two.height {
    True -> Nil
    False -> {
      assert 0 = 1
      Nil
    }
  }

  Input(risks: stitched_risks, width: one.width + two.width, height: one.height)
}

fn stitch_together_y(one: Input, two: Input) {
  let stitched_risks = two.risks
  |> map.to_list()
  |> list.map(fn(entry) {
    let #(#(x, y), value) = entry
    let new_y = one.height + y
    #(#(x, new_y), value)
  })
  |> map.from_list()
  |> map.merge(one.risks)

  case one.width == two.width {
    True -> Nil
    False -> {
      assert 0 = 1
      Nil
    }
  }

  Input(risks: stitched_risks, height: one.height + two.height, width: one.width)
}

fn increment_risks(risks, amount) {
  risks
  |> map.to_list()
  |> list.map(fn(entry) {
    let #(key, value) = entry
    let unwrapped_value = value + amount
    let new_value = case unwrapped_value {
      1 -> 1
      2 -> 2
      3 -> 3
      4 -> 4
      5 -> 5
      6 -> 6
      7 -> 7
      8 -> 8
      9 -> 9
      10 -> 1
      11 -> 2
      12 -> 3
      13 -> 4
      14 -> 5
      15 -> 6
      16 -> 7
      17 -> 8
      18 -> 9
      19 -> 1
      20 -> 2
    }

    #(key, new_value)
  })
  |> map.from_list()
}

fn calc_part_2(data) {
  let supermap = list.range(0, 5)
  |> list.map(fn(x) {
    list.range(0, 5)
    |> list.map(fn(y) {
      Input(..data, risks: increment_risks(data.risks, x + y))
    })
    |> list.reduce(stitch_together_x)
    |> result.unwrap(data)
  })
  |> list.reduce(stitch_together_y)
  |> result.unwrap(data)

  calc_part_1(supermap)
}

pub fn part1() {
  assert 2 = calc_part_1("11
21" |> parse())
  assert 40 = calc_part_1("1163751742
1381373672
2136511328
3694931569
7463417111
1319128137
1359912421
3125421639
1293138521
2311944581" |> parse())
  assert 685 = calc_part_1(input() |> parse())
}

pub fn part2() {
  calc_part_2(input() |> parse())
}
