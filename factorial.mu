# example program: compute the factorial of 5

recipe main [
  local-scope
  x:number <- factorial 5
  $print [result: ], x:number, [ 
]
]

recipe factorial [
  local-scope
  n:number <- next-ingredient
  {
    # if n=0 return 1
    zero?:boolean <- equal n:number, 0
    break-unless zero?:boolean
    reply 1
  }
  # return n * factorial(n-1)
  x:number <- subtract n:number, 1
  subresult:number <- factorial x:number
  result:number <- multiply subresult:number, n:number
  reply result:number
]

# unit test
scenario factorial-test [
  run [
    1:number <- factorial 5
  ]
  memory-should-contain [
    1 <- 120
  ]
]
