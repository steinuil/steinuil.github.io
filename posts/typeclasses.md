The other day I found myself trying to explain what I liked about Ur/Web typeclasses
and how they worked, and I realized that my comment would probably end up long
enough to be a half decent post, so here I am.

The concept behind typeclasses is actually pretty simple, and it can be
implemented in any language that supports generics and functions as arguments
to other functions. Which is basically all modern languages.
Given a normal increase function:

```javascript
const incr = (n) =>
  n + 1;
```

We can hoist the increment operation into the arguments to the function,
letting us provide our own implementation.

```javascript
const incr = (incrementor) => (n) =>
  incrementor(n);

incr(x => x + 1)(1)
```

The usefulness of this starts becoming clearer when you define more complex
operations on top of of the basic ones:

```javascript
const isZero = (counter) => (n) => counter.isZero(n);
const incr = (counter) => (n) => counter.incr(n);
const decr = (counter) => (n) => counter.decr(n);

const add = (counter) => (n, m) =>
  isZero(counter)(m) ? n :
    add(counter)(incr(counter)(n), decr(counter)(m));

const counter = {
  isZero: (n) => { return n === 0; },
  incr: (n) => { return n + 1; },
  decr: (n) => { return n - 1; }
};

add(counter)(1, 2);
```

The arguments to `add` don't necessarily have to be numbers: they can be
anything, as long as you provide a suitable implementation of `counter`.

```javascript
const screamer = {
  isZero: (s) => { return s.length === 0; },
  incr: (s) => { return s + "A"; },
  decr: (s) => { return s.slice(0, -1); }
};

add(screamer)("AA", "AAAAAA");
```

We could also write a generic json encoding function (I know these are awful
JSON encoding functions, just bear with me for a moment):

```javascript
const jsonEncode = (encoder) => (j) =>
  encoder(j);

const encodeString = (s) =>
  "\"" + s.replace("\"", "\\\"") + "\"";

const encodeInt = (i) =>
  i.toString();

const encodePair = (e1, e2) =>
  (p) =>
    "[" + e1(p[0]) + "," + e2(p[1]) + "]";

jsonEncode(encodePair(encodeString, encodeInt))
  (["The sun went down with practiced bravado.", 451]);
```

If you've ever used Elm, this might remind you of Json.Decode's interface,
which has you building up a decoder implementation function with the right type
for your desired object out of smaller decoder functions.

## Typeclasses

Now imagine passing the implementation as the first argument to almost every
function call in your codebase. Do you feel like gouging your eyes out yet?
Fret not, for type classes are here to the rescue!

Type classes are more or less a mechanism for inferring the right
implementation based on the type of the arguments, so you don't have
to write it explicitly. Some languages that implement them at language level
are Haskell, Scala and Ur/Web. There's an ongoing effort to embed type classes
into OCaml in the form of [modular implicits](http://ocamllabs.io/doc/implicits.html),
but it seems to be progressing slowly.

Ur/Web's implementation introduces a keyword, `class`, with which you can
declare a constructor type that will be specially marked by the compiler, and
lets you defined implementations as normal values:

```ur
(* counter.mli *)
class counter

val incr : t ::: Type -> counter t -> t -> t
val decr : t ::: Type -> counter t -> t -> t
val isZero : t ::: Type -> counter t -> t -> bool
val mkCounter : t ::: Type
  -> { Incr : t -> t, Decr : t -> t, IsZero : t -> bool }
  -> counter t

val counter_int : counter int
val counter_scream : counter string

(* counter.ml *)
con counter a = { Incr : a -> a
                , Decr : a -> a
                , IsZero : a -> bool }

fun mkCounter [a]
  (x : { Incr : a -> a
       , Decr : a -> a
       , IsZero : a -> bool }) =
  x

fun incr [a] (c : counter a) : a -> a = c.Incr
fun decr [a] (c : counter a) : a -> a = c.Decr
fun isZero [a] (c : counter a) : a -> bool = c.IsZero

val counter_int =
  mkCounter { Incr = fn x => x + 1
            , Decr = fn x => x - 1
            , IsZero = fn x => x = 0 }

val counter_scream =
  mkCounter { Incr = fn x => x ^ "A"
            , Decr = fn x => substring x 0 ((strlen x) - 1)
            , IsZero = fn x => x = "" }
```

Registering a function as a possible implementation for a typeclass is just
a matter of calling it with a properly typed function. Now we can use `incr`,
`decr` and `isZero` freely on the types we have provided an implementation for
without specifying the implementations explicitly.

```ur
incr 1
(* => 2 *)

decr "AAA"
(* => "AA" *)

isZero True
(* will not compile *)
```

We can provide multiple implementations for any given type, and Ur/Web will
choose the last one we have registered. Since typeclass implementations here
are just normal values, only typeclass implementations that are currently in
scope will be available, and if we want to force a specific implementation we
can pass it explicitly.

```ur
incr [some_counter_implementation] 1
(* => 2 *)
```

Haskell's typeclasses work a little differently: typeclasses are not quite like
normal types, and there's a special syntax for defining implementations, here
called *instances*, of a particular class. The compiler does not attempt any
sort of instance resolution and will complain if it finds more than one
implementation of a particular typeclass in the same program. This leads to a
few annoyances, because a library is not allowed to define its own private
implementation of a typeclass without polluting the global namespace. This
is usually solved by using newtypes, which is kind of unwieldy.

I don't know Scala, but its type classes are called "implicits" and they seem
to be similar to Ur/Web's, save for not supporting multiple implementations in
scope.

OCaml's modular implicits are a lot like Ur/Web's, but their use is constrained
to modules rather than any kind of value. As in Ur/Web, there's a special
syntax for forcing a specific implementation for a certain type to be used,
but unlike Ur/Web and as in Scala only one implicit module is allowed in scope.
It's also possible to use a non-implicit module as implementation by passing it
explicitly, so even if there is an implicit module already in scope it's easy
to override it.

## Further reading

- [Leo White, Frédéric Bour, Jeremy Yallop: Modular implicits](https://arxiv.org/pdf/1512.01895.pdf), the paper presenting OCaml's modular implicits
- [Implementing, and Understanding Type Classes](http://okmij.org/ftp/Computation/typeclass.html) by Oleg Kiselyov
- [Scrap your type classes](http://www.haskellforall.com/2012/05/scrap-your-type-classes.html) for an implementation of the more explicit kind of typeclasses in Haskell
- [Elm type system extensions issue](https://github.com/elm-lang/elm-compiler/issues/1039) to admire the lack of discussion of this issue in the Elm language
- [Critique of implicits](https://discuss.ocaml.org/t/critique-of-implicits/3031)
