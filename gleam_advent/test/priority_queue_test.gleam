import priority_queue

pub fn gives_you_items_test() {
  let queue = priority_queue.new()
  let queue = priority_queue.insert(queue, "high", 1)
  let queue = priority_queue.insert(queue, "low", 10)

  assert Ok(#("high", queue)) = priority_queue.pop(queue)
  assert Ok(#("low", queue)) = priority_queue.pop(queue)
  assert Error(Nil) = priority_queue.pop(queue)
}

pub fn priority_can_change_test() {
  let queue = priority_queue.new()
  let queue = priority_queue.insert(queue, "one", 1)
  let queue = priority_queue.insert(queue, "two", 10)
  let queue = priority_queue.insert(queue, "one", 1000)

  assert Ok(#("two", queue)) = priority_queue.pop(queue)
  assert Ok(#("one", queue)) = priority_queue.pop(queue)
  assert Error(Nil) = priority_queue.pop(queue)
}

pub fn main() {
  gives_you_items_test()
  priority_can_change_test()
}
