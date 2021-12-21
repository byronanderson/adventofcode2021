import gleam/map
import utils

external type Ref
external fn make_ref() -> Ref = "erlang" "make_ref"

external type PQueue(a)
pub opaque type PriorityQueue(a) {
  PriorityQueue(queue: PQueue(#(a, Ref)), refs: map.Map(a, Ref))
}

type OutResult(a) {
  Empty
  Value(a, Int)
}

external fn new_() -> PQueue(a) = "pqueue2" "new"
external fn insert_(a, Int, PQueue(a)) -> PQueue(a) = "pqueue2" "in"
external fn pop_(PQueue(a)) -> #(OutResult(a), PQueue(a)) = "pqueue2" "pout"

pub fn new() -> PriorityQueue(a) {
  PriorityQueue(
    queue: new_(),
    refs: map.new()
  )
}

pub fn insert(queue: PriorityQueue(a), value: a, priority: Int) -> PriorityQueue(a) {
  let ref = make_ref()

  let refs = queue.refs
  |> map.insert(value, ref)

  PriorityQueue(
    refs: refs,
    queue: insert_(#(value, ref), priority, queue.queue)
  )
}

pub fn pop(queue: PriorityQueue(a)) -> Result(#(a, PriorityQueue(a)), Nil) {
  case pop_(queue.queue) {
    #(Value(#(value, ref), _priority), pqueue) -> {
      assert Ok(recently_enqueued_ref) = map.get(queue.refs, value)
      case recently_enqueued_ref == ref {
        True -> Ok(#(value, PriorityQueue(refs: queue.refs, queue: pqueue)))
        False -> pop(PriorityQueue(refs: queue.refs, queue: pqueue))
      }
    }
    #(Empty, _pqueue) -> {
      Error(Nil)
    }
  }
}
