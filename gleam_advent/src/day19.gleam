import utils
import gleam/string
import gleam/result
import gleam/regex
import gleam/option
import gleam/bool
import gleam/pair
import gleam/set
import gleam/map
import gleam/int
import gleam/list

fn input() {
  assert Ok(data) = utils.read_file("input_day19.txt")
  data |> string.trim()
}

fn example() {
  assert Ok(data) = utils.read_file("example_day19.txt")
  data |> string.trim()
}

type RelativePosition {
  RelativePosition(x: Int, y: Int, z: Int)
}

type ScannerReadout {
  ScannerReadout(id: Int, relative_positions: List(RelativePosition))
}

type Input = List(ScannerReadout)

fn parse(input: String) {
  input
  |> string.split("\n\n")
  |> list.map(assert_parse_scanner_readout)
}

fn assert_parse_scanner_readout(input: String) {
  let [first_line, ..position_lines] = input |> string.split("\n")

  assert Ok(re) = regex.from_string("--- scanner (\\d+) ---")
  assert [regex.Match(_, [option.Some(id_string)])] = regex.scan(re, first_line)

  let id = utils.assert_parse_int(id_string)

  let positions = position_lines |> list.map(assert_parse_position)

  ScannerReadout(id: id, relative_positions: positions)
}

fn assert_parse_position(input: String) {
  assert [x, y, z] = string.split(input, ",") |> list.map(utils.assert_parse_int)
  RelativePosition(x, y, z)
}

fn detect_similarity(scan_1: ScannerReadout, scan_2: ScannerReadout) -> Result(#(ScannerReadout, RelativePosition), Nil) {
  let reference_scan_set = set.from_list(scan_1.relative_positions)

  all_orientations(scan_2)
  |> list.find_map(fn(positions_2: List(RelativePosition)) {
    // see if any individual point of scan_1 matches any individual point
    // in positions_2
    list.find_map(scan_1.relative_positions, fn(point: RelativePosition) {
      // see if we force this point and any other point in positions_2 to be
      // the same, that they work out nicely
      list.find_map(positions_2, fn(candidate_equivalent_point: RelativePosition) {
        let offset_x = candidate_equivalent_point.x - point.x
        let offset_y = candidate_equivalent_point.y - point.y
        let offset_z = candidate_equivalent_point.z - point.z
        // case offset_x == -68 {
        //   True ->  {
        // utils.inspect(#(offset_x, offset_y, offset_z))
        // Nil
        //   }
        //   False -> Nil
        // }
        let reoriented_positions = positions_2
        |> list.map(fn(position: RelativePosition) {
          RelativePosition(
            x: position.x - offset_x,
            y: position.y - offset_y,
            z: position.z - offset_z
          )
        })

        let intersection = reoriented_positions
        |> set.from_list()
        |> set.intersection(reference_scan_set)

        // case offset_x == -68 {
        //   True ->  {
        // utils.inspect(set.size(intersection))
        // Nil
        //   }
        //   False -> Nil
        // }

        case set.size(intersection) >= 12 {
          True -> Ok(#(ScannerReadout(scan_2.id, reoriented_positions), RelativePosition(offset_x, offset_y, offset_z)))
          False -> Error(Nil)
        }
      })
    })
  })
}

type Axis {
  XAxis
  YAxis
  ZAxis
}

fn list_without(input: List(a), element: a) -> List(a) {
  input
  |> list.filter(fn(x) { x != element })
}

fn all_orientations(scan: ScannerReadout) -> List(List(RelativePosition)) {
  let axes: List(Axis) = [XAxis, YAxis, ZAxis]
  list.flat_map([1, -1], fn(x_multiplier) {
    list.flat_map([1, -1], fn(y_multiplier) {
      list.flat_map([1, -1], fn(z_multiplier) {
        list.flat_map(axes, fn(what_is_x: Axis) {
          list.map(axes |> list_without(what_is_x), fn(what_is_y: Axis) {
            scan.relative_positions
            |> list.map(fn(position) {
              let RelativePosition(x, y, z) = position
              let x = x * x_multiplier
              let y = y * y_multiplier
              let z = z * z_multiplier
              case #(what_is_x, what_is_y) {
                #(XAxis, YAxis) -> RelativePosition(x: x, y: y, z: z)
                #(XAxis, ZAxis) -> RelativePosition(x: x, y: z, z: y)
                #(YAxis, ZAxis) -> RelativePosition(x: y, y: z, z: x)
                #(YAxis, XAxis) -> RelativePosition(x: y, y: x, z: z)
                #(ZAxis, XAxis) -> RelativePosition(x: z, y: x, z: y)
                #(ZAxis, YAxis) -> RelativePosition(x: z, y: y, z: x)
              }
            })
          })
        })
      })
    })
  })
}

fn calc_part_1(data: Input) {
  let #(output, _scanner_positions) = reconcile(data, set.new())
  list.length(output.relative_positions)
}

fn reconcile(data: Input, positions: set.Set(RelativePosition)) -> #(ScannerReadout, set.Set(RelativePosition)) {
  utils.inspect(list.length(data))
  case data {
    [reference_scan] -> #(reference_scan, positions)
    [reference_scan, ..other_scans] -> {
      let similarities = other_scans |> list.filter_map(detect_similarity(reference_scan, _))

      let positions = similarities
      |> list.map(pair.second)
      |> set.from_list()
      |> set.union(positions)
      let new_reference_scan = similarities
      |> list.map(pair.first)
      |> list.fold(reference_scan, fn(scan: ScannerReadout, other_scan: ScannerReadout) {
        ScannerReadout(
          id: scan.id,
          relative_positions: other_scan.relative_positions
            |> list.append(scan.relative_positions)
            |> set.from_list()
            |> set.to_list()
        )
      })
      let now_similar_scan_ids = similarities |> list.map(pair.first) |> list.map(fn(scan: ScannerReadout) { scan.id }) |> set.from_list()
      let unmatched_scans = other_scans |> list.filter(fn(scan: ScannerReadout) {
        set.contains(now_similar_scan_ids, scan.id)
        |> bool.negate()
      })

      reconcile([new_reference_scan, ..unmatched_scans], positions)
    }
  }
}

fn distance_between(pos1: RelativePosition, pos2: RelativePosition) -> Int {
  [
    int.absolute_value(pos1.x - pos2.x),
    int.absolute_value(pos1.y - pos2.y),
    int.absolute_value(pos1.z - pos2.z),
  ]
  |> int.sum()
}

fn calc_part_2(data) {
  let #(_output, scanner_positions) = reconcile(data, set.new() |> set.insert(RelativePosition(0, 0, 0)))
  scanner_positions
  |> set.to_list()
  |> list.combination_pairs()
  |> list.map(fn(pair) {
    let #(position1, position2) = pair
    distance_between(position1, position2)
  })
  |> list.sort(int.compare)
  |> list.last()
  |> result.unwrap(-1)
}

pub fn part1() {
  assert 79 = calc_part_1(example() |> parse())
  calc_part_1(input() |> parse())
}

pub fn part2() {
  assert 3621 = calc_part_2(example() |> parse())
  calc_part_2(input() |> parse())
}
