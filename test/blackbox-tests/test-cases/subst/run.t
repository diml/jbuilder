  $ git init &> /dev/null
  $ git add . &> /dev/null
  $ git commit -am _ &> /dev/null
  $ git tag -a 1.0 -m 1.0
  $ dune subst
  $ cat file.ml
  let name = "foo"
  let authors = "John Doe <john@doe.com>"
  let version = "1.0"

To avoid the issue exposed in ../action-modifying-a-dependency:

  $ git reset --hard &> /dev/null
