import gleam/map
import gleam/list
import gleam/option

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
