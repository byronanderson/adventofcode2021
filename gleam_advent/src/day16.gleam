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
  assert Ok(data) = utils.read_file("input_day16.txt")
  data |> string.trim()
}

fn parse(input: String) {
  input
}

fn hex_to_binary(input: String) -> String {
  input
  |> string.to_graphemes()
  |> hex_to_binary_([])
}

fn hex_to_binary_(input: List(String), acc: List(String)) {
  case input {
    [] -> list.reverse(acc) |> string.join("")
    [first, ..rest] -> {
      let binary = case first {
        "0" -> "0000"
        "1" -> "0001"
        "2" -> "0010"
        "3" -> "0011"
        "4" -> "0100"
        "5" -> "0101"
        "6" -> "0110"
        "7" -> "0111"
        "8" -> "1000"
        "9" -> "1001"
        "A" -> "1010"
        "B" -> "1011"
        "C" -> "1100"
        "D" -> "1101"
        "E" -> "1110"
        "F" -> "1111"
      }
      hex_to_binary_(rest, [binary, ..acc])
    }
  }
}

fn extract_section(binary: String, offset: Int, length: Int) {
  binary
  |> string.slice(offset, length)
  |> binary_to_int()
}

fn binary_to_int(binary: String) -> Int {
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

type Packet {
  LiteralPacket(version: Int, value: Int)
  OperatorPacket(version: Int, subpackets: List(Packet), operator: Operator)
}

type Operator {
  Sum
  Product
  Minimum
  Maximum
  GreaterThan
  LessThan
  EqualTo
}

fn parse_literal(binary: String) -> #(Int, String) {
  parse_literal_(binary, 6, 0)
}

fn parse_literal_(binary: String, bit_offset, acc) {
  let group_bit = extract_section(binary, bit_offset, 1)
  let number = extract_section(binary, bit_offset + 1, 4)

  let new_acc = acc * 16 + number
  case group_bit {
    0 -> #(new_acc, string.drop_left(binary, bit_offset + 5))
    1 -> parse_literal_(binary, bit_offset + 5, new_acc)
  }
}
fn extract_other_packet(binary: String, packet_version, packet_type) {
  let length_type = extract_section(binary, 6, 1)
  case length_type {
    0 -> {
      let length_in_bits = extract_section(binary, 7, 15)
      let subpacket_binary = string.slice(binary, 7 + 15, length_in_bits)
      let subpackets = parse_packets(subpacket_binary)
      let rest = string.drop_left(binary, 7 + 15 + length_in_bits)
      let packet = OperatorPacket(version: packet_version, operator: operator(packet_type), subpackets: subpackets)
      #(packet, rest)
    }
    1 -> {
      let number_of_packets = extract_section(binary, 7, 11)
      let subpacket_binary = string.drop_left(binary, 7 + 11)
      let #(subpackets, rest) = parse_number_of_packets(subpacket_binary, number_of_packets)
      let packet = OperatorPacket(version: packet_version, operator: operator(packet_type), subpackets: subpackets)
      #(packet, rest)
    }
  }
}

fn parse_number_of_packets(binary: String, number: Int) -> #(List(Packet), String) {
  parse_number_of_packets_(binary, number, [])
}

fn parse_number_of_packets_(binary, number, acc) {
  case number {
    0 -> #(list.reverse(acc), binary)
    _ -> {
      let #(packet, rest) = parse_packet(binary)
      parse_number_of_packets_(rest, number - 1, [packet, ..acc])
    }
  }
}

fn parse_packets(binary: String) {
  parse_packets_(binary, [])
}

fn parse_packets_(binary: String, acc: List(Packet)) {
  case string.length(binary) {
    0 -> list.reverse(acc)
    _ -> {
      let #(packet, rest) = parse_packet(binary)
      parse_packets_(rest, [packet, ..acc])
    }
  }
}

fn parse_packet(binary) {
  let packet_version = extract_section(binary, 0, 3)
  let packet_type = extract_section(binary, 3, 3)

  case packet_type {
    4 -> {
      let #(value, rest) = parse_literal(binary)
      #(LiteralPacket(version: packet_version, value: value), rest)
    }
    _other -> {
      extract_other_packet(binary, packet_version, packet_type)
    }
  }
}

fn operator(packet_type: Int) {
  case packet_type {
    0 -> Sum
    1 -> Product
    2 -> Minimum
    3 -> Maximum
    5 -> GreaterThan
    6 -> LessThan
    7 -> EqualTo
  }
}

fn score(packet: Packet) {
  case packet {
    OperatorPacket(version, subpackets, _) -> {
      let subsum = subpackets |> list.map(score) |> int.sum()
      subsum + version
    }
    LiteralPacket(version, _) -> version
  }
}

fn calculate(packet: Packet) {
  case packet {
    LiteralPacket(_, value) -> value
    OperatorPacket(_, subpackets, operator) -> {
      let subvalues = subpackets |> list.map(calculate)
      case operator {
        Sum -> int.sum(subvalues)
        Product -> list.fold(subvalues, 1, fn(x, y) { x * y })
        Minimum -> subvalues |> list.sort(int.compare) |> list.first() |> result.unwrap(0)
        Maximum -> subvalues |> list.sort(int.compare) |> list.last() |> result.unwrap(0)
        LessThan -> {
          assert [first, second] = subvalues
          case first < second {
            True -> 1
            False -> 0
          }
        }
        GreaterThan -> {
          assert [first, second] = subvalues
          case first > second {
            True -> 1
            False -> 0
          }
        }
        EqualTo -> {
          assert [first, second] = subvalues
          case first == second {
            True -> 1
            False -> 0
          }
        }
      }
    }
  }
}

fn calc_part_1(data) {
  let binary = data
    |> hex_to_binary()

  let #(packet, _) = parse_packet(binary)
  score(packet)
}

fn calc_part_2(data) {
  let binary = data
    |> hex_to_binary()

  let #(packet, _) = parse_packet(binary)

  calculate(packet)
}

pub fn part1() {
  calc_part_1("D2FE28")
  assert 16 = calc_part_1("8A004A801A8002F478")
  calc_part_1(input())
}

pub fn part2() {
  calc_part_2(input())
}
