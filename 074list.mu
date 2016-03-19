# A list links up multiple objects together to make them easier to manage.
#
# The objects must be of the same type. If you want to store multiple types in
# a single list, use an exclusive-container.

container list:_elem [
  value:_elem
  next:address:shared:list:_elem
]

def push x:_elem, in:address:shared:list:_elem -> in:address:shared:list:_elem [
  local-scope
  load-ingredients
  result:address:shared:list:_elem <- new {(list _elem): type}
  val:address:_elem <- get-address *result, value:offset
  *val <- copy x
  next:address:address:shared:list:_elem <- get-address *result, next:offset
  *next <- copy in
  return result  # needed explicitly because we need to replace 'in' with 'result'
]

def first in:address:shared:list:_elem -> result:_elem [
  local-scope
  load-ingredients
  result <- get *in, value:offset
]

def rest in:address:shared:list:_elem -> result:address:shared:list:_elem/contained-in:in [
  local-scope
  load-ingredients
  result <- get *in, next:offset
]

scenario list-handling [
  run [
    1:address:shared:list:number <- push 3, 0
    1:address:shared:list:number <- push 4, 1:address:shared:list:number
    1:address:shared:list:number <- push 5, 1:address:shared:list:number
    2:number <- first 1:address:shared:list:number
    1:address:shared:list:number <- rest 1:address:shared:list:number
    3:number <- first 1:address:shared:list:number
    1:address:shared:list:number <- rest 1:address:shared:list:number
    4:number <- first 1:address:shared:list:number
    1:address:shared:list:number <- rest 1:address:shared:list:number
  ]
  memory-should-contain [
    1 <- 0  # empty to empty, dust to dust..
    2 <- 5
    3 <- 4
    4 <- 3
  ]
]

def to-text in:address:shared:list:_elem -> result:address:shared:array:character [
  local-scope
  load-ingredients
  buf:address:shared:buffer <- new-buffer 80
  buf <- to-buffer in, buf
  result <- buffer-to-array buf
]

# variant of 'to-text' which stops printing after a few elements (and so is robust to cycles)
def to-text-line in:address:shared:list:_elem -> result:address:shared:array:character [
  local-scope
  load-ingredients
  buf:address:shared:buffer <- new-buffer 80
  buf <- to-buffer in, buf, 6  # max elements to display
  result <- buffer-to-array buf
]

def to-buffer in:address:shared:list:_elem, buf:address:shared:buffer -> buf:address:shared:buffer [
  local-scope
  load-ingredients
  {
    break-if in
    buf <- append buf, 48/0
    return
  }
  # append in.value to buf
  val:_elem <- get *in, value:offset
  buf <- append buf, val
  # now prepare next
  next:address:shared:list:_elem <- rest in
  nextn:number <- copy next
  return-unless next
  buf <- append buf, [ -> ]
  # and recurse
  remaining:number, optional-ingredient-found?:boolean <- next-ingredient
  {
    break-if optional-ingredient-found?
    # unlimited recursion
    buf <- to-buffer next, buf
    return
  }
  {
    break-unless remaining
    # limited recursion
    remaining <- subtract remaining, 1
    buf <- to-buffer next, buf, remaining
    return
  }
  # past recursion depth; insert ellipses and stop
  append buf, [...]
]
