//: Containers contain a fixed number of elements of different types.

:(before "End Mu Types Initialization")
//: We'll use this container as a running example, with two integer elements.
type_number point = Type_number["point"] = Next_type_number++;
Type[point].size = 2;
Type[point].kind = container;
Type[point].name = "point";
vector<type_number> i;
i.push_back(integer);
Type[point].elements.push_back(i);
Type[point].elements.push_back(i);

:(scenario copy_multiple_locations)
# Containers can be copied around with a single instruction just like integers,
# no matter how large they are.
recipe main [
  1:integer <- copy 34:literal
  2:integer <- copy 35:literal
  3:point <- copy 1:point
]
+run: ingredient 0 is 1
+mem: location 1 is 34
+mem: location 2 is 35
+mem: storing 34 in location 3
+mem: storing 35 in location 4

:(before "End Mu Types Initialization")
// A more complex container, containing another container as one of its
// elements.
type_number point_integer = Type_number["point-integer"] = Next_type_number++;
Type[point_integer].size = 2;
Type[point_integer].kind = container;
Type[point_integer].name = "point-integer";
vector<type_number> p2;
p2.push_back(point);
Type[point_integer].elements.push_back(p2);
vector<type_number> i2;
i2.push_back(integer);
Type[point_integer].elements.push_back(i2);

:(scenario copy_handles_nested_container_elements)
recipe main [
  12:integer <- copy 34:literal
  13:integer <- copy 35:literal
  14:integer <- copy 36:literal
  15:point-integer <- copy 12:point-integer
]
+mem: storing 36 in location 17

:(before "End size_of(types) Cases")
type_info t = Type[types[0]];
if (t.kind == container) {
  // size of a container is the sum of the sizes of its elements
  size_t result = 0;
  for (index_t i = 0; i < t.elements.size(); ++i) {
    result += size_of(t.elements[i]);
  }
  return result;
}

//:: To access elements of a container, use 'get'
:(scenario get)
recipe main [
  12:integer <- copy 34:literal
  13:integer <- copy 35:literal
  15:integer <- get 12:point, 1:offset
]
+run: instruction main/2
+run: ingredient 0 is 12
+run: ingredient 1 is 1
+run: address to copy is 13
+run: its type is 1
+mem: location 13 is 35
+run: product 0 is 35
+mem: storing 35 in location 15

:(before "End Primitive Recipe Declarations")
GET,
:(before "End Primitive Recipe Numbers")
Recipe_number["get"] = GET;
:(before "End Primitive Recipe Implementations")
case GET: {
  trace("run") << "ingredient 0 is " << current_instruction().ingredients[0].name;
  reagent base = current_instruction().ingredients[0];
  int base_address = base.value;
  int base_type = base.types[0];
  assert(Type[base_type].kind == container);
  trace("run") << "ingredient 1 is " << current_instruction().ingredients[1].name;
  assert(isa_literal(current_instruction().ingredients[1]));
  index_t offset = current_instruction().ingredients[1].value;
  int src = base_address;
  for (index_t i = 0; i < offset; ++i) {
    src += size_of(Type[base_type].elements[i]);
  }
  trace("run") << "address to copy is " << src;
  assert(Type[base_type].kind == container);
  assert(Type[base_type].elements.size() > offset);
  int src_type = Type[base_type].elements[offset][0];
  trace("run") << "its type is " << src_type;
  reagent tmp;
  tmp.set_value(src);
  tmp.types.push_back(src_type);
  vector<int> result(read_memory(tmp));
  trace("run") << "product 0 is " << result[0];
  write_memory(current_instruction().products[0], result);
  break;
}

//: 'get' requires a literal in ingredient 1. We'll use a synonym called
//: 'offset'.
:(before "End Mu Types Initialization")
Type_number["offset"] = 0;

:(scenario get_handles_nested_container_elements)
recipe main [
  12:integer <- copy 34:literal
  13:integer <- copy 35:literal
  14:integer <- copy 36:literal
  15:integer <- get 12:point-integer, 1:offset
]
+run: instruction main/2
+run: ingredient 0 is 12
+run: ingredient 1 is 1
+run: address to copy is 14
+run: its type is 1
+mem: location 14 is 36
+run: product 0 is 36
+mem: storing 36 in location 15

//:: To write to elements of containers, you need their address.

:(scenario get_address)
recipe main [
  12:integer <- copy 34:literal
  13:integer <- copy 35:literal
  15:address:integer <- get-address 12:point, 1:offset
]
+run: instruction main/2
+run: ingredient 0 is 12
+run: ingredient 1 is 1
+run: address to copy is 13
+mem: storing 13 in location 15

:(before "End Primitive Recipe Declarations")
GET_ADDRESS,
:(before "End Primitive Recipe Numbers")
Recipe_number["get-address"] = GET_ADDRESS;
:(before "End Primitive Recipe Implementations")
case GET_ADDRESS: {
  trace("run") << "ingredient 0 is " << current_instruction().ingredients[0].name;
  reagent base = current_instruction().ingredients[0];
  int base_address = base.value;
  int base_type = base.types[0];
  assert(Type[base_type].kind == container);
  trace("run") << "ingredient 1 is " << current_instruction().ingredients[1].name;
  assert(isa_literal(current_instruction().ingredients[1]));
  index_t offset = current_instruction().ingredients[1].value;
  int src = base_address;
  for (index_t i = 0; i < offset; ++i) {
    src += size_of(Type[base_type].elements[i]);
  }
  trace("run") << "address to copy is " << src;
  vector<int> result;
  result.push_back(src);
  trace("run") << "product 0 is " << result[0];
  write_memory(current_instruction().products[0], result);
  break;
}
