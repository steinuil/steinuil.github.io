+++
title = "Reading Ur/Web signatures, part 1"
date = 2019-01-07
+++

So you stumbled upon Ur/Web and you rather like what it's about, but after
trudging through the tutorials and the examples in the few blog posts you've
seen around you can't seem to find your own footing. The compiler errors are
long and life is short and you're about to throw your computer out the window.

[I understand.](/blog/urweb/)

In this post, I'll walk you through the signatures of a few functions from the
standard library, hopefully providing you with enough context to make it
through the rest on your own. You might want to grab [a copy][stdlib] or search
for the one on your hard drive so you can follow along.

I'm going to be frank: given the current state of the ecosystem and of the
documentation, you have close to no chance of learning Ur/Web if you don't
already know some OCaml/ReasonML or another language in the ML family, so
if you don't you might want to get well acquainted with one first.
[Elm](https://elm-lang.org/) is a good starting point.

Open up `string.urs` and have a look around. I'm going to assume you can read
these signatures:

```mli
type t = string

val length : t -> int

val append : t -> t -> t

val all : (char -> bool) -> string -> bool
```

Still here? Good, let's introduce some new syntax.

```mli
val index : string -> char -> option int
```

If you come from OCaml or SML you might notice that the argument of the type
constructor `option` is to the right of the constructor, as in normal function
application. This unification of function and type constructor application is
not just a matter of syntax like in [ReasonML][reason-params]; put this in the
back of your mind for the moment, we'll come back to it later.

```mli
val substring : string -> {Start : int, Len : int} -> string
```

Much like SML, Ur/Web makes up for the lack of labeled arguments by using
anonymous records as function arguments. Also, record field names must start
with a capital letter like the members of a variant.

## Generics

Let's kick things up a notch. Open up `list.urs` and you'll be greeted by
something like this:

```mli
val rev : a ::: Type -> list a -> list a
```

As you might have guessed, `List.rev` is a function that takes a list of
elements and returns another list with the elements of the first, in reverse
order. `rev` can reverse lists that contain any element, so we say that it is
*polymorphic*.

`a` is the type of the values contained in the input and output list. The
argument `a ::: Type` is just a way of saying that we don't know what type `a`
will be when we declare the function; it's up to the caller to bind it to a
valid type. The triple colon (`:::`) means that this type parameter is
implicit, so the compiler will take care of inserting the correct type when
calling it.

OCaml and most other languages don't require you to explicitly declare these
type parameter, but [sometimes it is useful][ocaml-poly] to ensure the
well-typedness of a polymorphic function.

Quoting from the [tutorial](http://www.impredicative.com/ur/tutorial/intro.html):

> Unlike in ML and Haskell, polymorphic functions in Ur/Web often require full
> type annotations. That is because more advanced features make Ur type
> inference undecidable.

Let's pull up the implementation for a moment (found in `list.ur`):

```ml
fun rev [a] (ls : list a) = ...
```

The `a` in square brackets here corresponds to `a ::: Type` in the signature
above. We could also write it like `[a ::: Type]` if we wanted to be more
explicit.

Now let's look at `List.mp`. (Which is just the `List.map` function, but it
can't be called `map` because `map` is a keyword in Ur/Web. More on that later.)

```mli
val mp : a ::: Type -> b ::: Type -> (a -> b) -> list a -> list b
```

`mp` has two polymorphic type parameters, so they are both made explicit in
the signature.

Interestingly, we can write a function so that the type parameter has to be
passed *explicitly* by replacing `:::` with a double colon (`::`):

```ml
(* id.urs *)
val id : a :: Type -> a -> a

(* id.ur *)
fun id [a :: Type] (x : a) = x

val x = id [int] 451
```

`:::` indicates a type parameter that may be inferred by the compiler, while
`::` indicates one that has to be passed explicitly. The compiler will be able
to infer a type parameter by itself most of the time, but in some cases which
we'll see later you'll have to be explicit and use the double colon.

## Basics of type constructors

At this point I should introduce Ur/Web's type constructors, because they're
a lot more powerful than those in most other languages. Open up `json.ur`
(not `json.urs`) and the first thing you'll see will be this:

```ml
con json a = {ToJson : a -> string,
              FromJson : string -> a * string}
```

While the `con` keyword might throw you off, you might recognize this as a
simple type declaration. Ur/Web actually makes a distinction between simple
aliases, like the one we encountered at the top of `string.urs`, and type
constructors, which take one (or more!) arguments, and have to be declared
with the keyword `con`.

The `json` type constructor is simply a record with an encoder function which
takes an `a` and returns a JSON string, and a decoder function which takes a
JSON string and returns an `a` and the remaining JSON string.

Remember that thing earlier about unifying function application and type
constructor application syntax? The two are actually very closely related:
just as normal functions are functions from values to values, type constructors
can be thought of as **type-level functions from types to types**, and the
purpose of this unification is just to make the similarity more apparent.

This insight might not net you much in OCaml or SML because type constructors
have a lot of limitations compared to functions: they can't be curried, and
you can perform very few operations inside them.

Ur/Web's type constructors are much more interesting. The `json` declaration
above is actually syntactic sugar for a type-level function:

```ml
con json = fn (a :: Type) =>
  {ToJson : a -> string,
   FromJson : string -> a * string}
```

We can define a **curried** constructor that takes two types and returns the
type of a 2-tuple:

```mli
con pair a b = a * b

con intAnd :: Type -> Type = pair int

val p : intAnd string = (451, "what a shame")
```

We can also perform various useful operations on record types, as we'll see
later.

## Type classes

Ur/Web's `=` (equals) operator works just like you'd expect it to for types
provived by the standard library: `1 = 1`, `"line" = "line"`,
and `Some "just" = Some "just"`. So is it implemented like in [OCaml][ocaml-eq],
using a "magic" internal function that structurally compares record fields
and variant members? Not quite.

If we try to compare two records, we'll get a surprisingly helpful error
message:

```mli
(* test.ur *)
val ok = { A = 1 } = { A = 1 }

(* test.ur:1:5: (to 1:26) Can't resolve type class instance
   Class constraint: eq {A : int} *)
```

Let's take a look into `basis.urs`. At line 26, you'll see these declarations:

```mli
class eq
val eq : t ::: Type -> eq t -> t -> t -> bool
```

The signature of the `eq` function looks familiar enough. We still don't know
what `class eq` means, but by the way it's used in the function we can infer
that it's a constructor that takes one argument.

In fact, `eq` is just an [abstract type][ocaml-abstract], i.e. a type whose
implementation isn't specified in its signature so that only the underlying
module can access it. If you don't know what that is, you can think of it as an
opaque pointer in C.

In this case we can't look at its actual implementation because `Basis` is
implemented directly in C, but it would look somewhat like this:

```mli
con eq t = t -> t -> bool
```

So now we should have all the pieces to understand the `eq` function above.
Or do we?

If you were to define your own `eq` constructor and your own `eq` function,
you'd always have to pass a function of type `eq t` as first argument.
(This kind of function can also be called **witness**.)

```mli
con eq' t = t -> t -> bool

fun eq' [t] (cmp : eq' t) (a : t) (b : t) =
  cmp a b

fun eq'_bool (a : bool) (b : bool) =
  case (a, b) of
  | (True, True) => True
  | (False, False) => True
  | _ => False

val test = eq' eq'_bool True False
```

But if we were to do the same with eq, we would get a compiler error.

Turns out that the `eq` function is just the desugared name of the `=`
operator, and as we've seen above, we can use it transparently without having
to worry about the witness function.
This is where the `class` keyword comes into play.

When we mark `eq` with the `class` keyword in a signature file, the compiler
will automatically search for a fitting implementation of `eq t` every time we
call `=` with a given `t`.

The `option` constructor also defines an `eq` witness in  the `Option` module.
This is its signature:

```mli
val eq : a ::: Type -> eq a -> eq (option a)
```

This should be straightforward by now. `Option.eq` implicitly takes a witness
`eq a` and maps it to the value stored inside the option, if any. Let's take
a look at its implementation.

```ml
fun eq [a] (_ : eq a) =
    mkEq (fn x y =>
             case (x, y) of
                 (None, None) => True
               | (Some x, Some y) => x = y
               | _ => False)
```

The wildcard corresponds to the witness argument, even though the function
doesn't use it directly. In a way, the witness argument is just there to
**constrain** the types we can call `Option.eq` with to those for which there
exists an implementation of `eq`.

Now the error message should make sense: the compiler is telling us that this
invocation of `=` has a constraint of type `eq {A : int}` on its arguments,
so we need to implement a witness of `eq` for `{A : int}`. We'll have to use
the `mkEq` function to do this.

```mli
val eq_a_int = mkEq
  (fn (a : {A : int}) (b : {B : int}) =>
    a.A = b.A)

(* this will compile now *)
val ok = { A = 1 } = { A = 1 }
```

## To be continued...

This post is getting pretty long, so I'll wrap it up here for this week.
If you already knew most of the things I covered here, don't worry, the next
one is gonna cover some of the most foreign parts of the type system.

Watch this space for part 2! (I promise I'll implement an RSS feed soon.)
In the meantime, you might want to brush up on [monads][ocaml-monad],
or take a look at the more dense [official tutorial][ur-tutorial].

[stdlib]: https://github.com/urweb/urweb/tree/master/lib/ur
[reason-params]: https://reasonml.github.io/docs/en/comparison-to-ocaml#type-parameters
[ocaml-poly]: https://blog.janestreet.com/ensuring-that-a-function-is-polymorphic-in-ocaml-3-12/
[ocaml-eq]: https://blog.janestreet.com/the-perils-of-polymorphic-compare/
[ocaml-abstract]: https://caml.inria.fr/pub/docs/manual-ocaml/moduleexamples.html#sec20
[ur-tutorial]: http://impredicative.com/ur/tutorial/
[ocaml-monad]: http://blog.haberkucharsky.com/technology/2015/07/21/more-monads-in-ocaml.html

