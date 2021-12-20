import gleam/map
import gleam/list
import gleam/string
import gleam/option
import gleam/int

external fn inspect_(a) -> a = "erlang" "display"
pub external fn sleep(a) -> a = "timer" "sleep"
pub external fn read_file(String) -> Result(String, a) = "file" "read_file"

// fn write_file(filename: String, content: String) -> Result(Nil, String) {
//   Error("not implemented")
// }

// fn file_exists(filename: String) -> Bool {
//   False
// }

pub fn inspect(value: a) -> a {
  inspect_(value)
  value
}

pub fn group_by(mylist, attribute) {
  mylist
  |> list.fold(map.new(), fn(acc, el) {
    map.update(acc, attribute(el), fn(current) {
      case current {
        option.Some(grouped_elements) -> [el, ..grouped_elements]
        option.None -> [el]
      }
    })
  })
}

pub fn assert_parse_int(input: String) -> Int {
  assert Ok(data) = int.parse(input)
  data
}

pub fn binary_to_int(binary: String) -> Int {
  binary
  |> string.to_graphemes()
  |> binary_to_int_(0)
}

fn binary_to_int_(chars, acc) {
  case chars {
    [] -> acc
    ["0", ..rest] -> binary_to_int_(rest, acc * 2)
    ["1", ..rest] -> binary_to_int_(rest, acc * 2 + 1)
  }
}
