//: So far we have local variables, and we can nest local variables of short
//: lifetimes inside longer ones. Now let's support 'global' variables that
//: last for the life of a routine. If we create multiple routines they won't
//: have access to each other's globals.
//:
//: This feature is still experimental and half-baked. You can't name global
//: variables, and they don't get checked for types (the only known hole in
//: the type system, can cause memory corruption). We might fix these issues
//: if we ever use globals. Or we might just drop the feature entirely.
//: [tag: todo]

:(scenario global_space)
def main [
  # pretend address:array:location; in practice we'll use new
  10:num <- copy 0  # refcount
  11:num <- copy 5  # length
  # pretend address:array:location; in practice we'll use new
  20:num <- copy 0  # refcount
  21:num <- copy 5  # length
  # actual start of this recipe
  global-space:space <- copy 20/unsafe
  default-space:space <- copy 10/unsafe
  1:num <- copy 23
  1:num/space:global <- copy 24
]
# store to default space: 10 + (skip refcount and length) 2 + (index) 1
+mem: storing 23 in location 13
# store to chained space: (contents of location 12) 20 + (refcount and length) 2 + (index) 1
+mem: storing 24 in location 23

//: to support it, create another special variable called global space
:(before "End is_disqualified Special-cases")
if (x.name == "global-space")
  x.initialized = true;
:(before "End is_special_name Special-cases")
if (s == "global-space") return true;

//: writes to this variable go to a field in the current routine
:(before "End routine Fields")
int global_space;
:(before "End routine Constructor")
global_space = 0;
:(after "Begin Preprocess write_memory(x, data)")
if (x.name == "global-space") {
  if (!scalar(data) || !is_space(x))
    raise << maybe(current_recipe_name()) << "'global-space' should be of type address:array:location, but tried to write '" << to_string(x.type) << "'\n" << end();
  if (Current_routine->global_space)
    raise << "routine already has a global-space; you can't over-write your globals" << end();
  Current_routine->global_space = data.at(0);
  return;
}

//: now marking variables as /space:global looks them up inside this field
:(after "int space_base(const reagent& x)")
  if (is_global(x)) {
    if (!Current_routine->global_space)
      raise << "routine has no global space\n" << end();
    return Current_routine->global_space + /*skip refcount*/1;
  }

//: for now let's not bother giving global variables names.
//: don't want to make them too comfortable to use.

:(scenario global_space_with_names)
def main [
  global-space:space <- new location:type, 10
  x:num <- copy 23
  1:num/space:global <- copy 24
]
# don't complain about mixing numeric addresses and names
$error: 0

:(after "bool is_numeric_location(const reagent& x)")
  if (is_global(x)) return false;

//: helpers

:(code)
bool is_global(const reagent& x) {
  string_tree* s = property(x, "space");
  return s && s->atom && s->value == "global";
}
