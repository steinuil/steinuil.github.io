So you've read [my post on Ur/Web](/molten-matter/urweb/) or you've stumbled
across the language

In this post, I'll walk you through the signatures of a few functions from the
standard library, hopefully providing some help in understanding the most
unreadable ones.

I'll assume you already know how to read basic type signatures in
OCaml/ReasonML or SML (which you should be familiar with if you actually want
to learn Ur/Web).

You might want to grab a copy of [the standard library][stdlib] or search for
the one on your hard drive so you can follow along.

Open up `string.urs` and have a look around. You should be able to tell what
these functions do:

```urs
type t = string

val length : t -> int

val append : t -> t -> t

val all : (char -> bool) -> string -> bool
```

Still here? Good, let's introduce some new syntax.

```urs
val index : string -> char -> option int
```

If you come from OCaml or SML you might notice that the argument of the type
constructor `option` is to the right of the constructor, as in normal function
application. This unification of function and type constructor application is
not just a matter of syntax like in [ReasonML][reason-params]; put it in the
back of your mind for the moment, we'll come back to it later.

```urs
val substring : string -> {Start : int, Len : int} -> string
```

Much like SML, Ur/Web makes up for the lack of labeled arguments by using
anonymous records as function arguments. Also, record field names must start
with a capital letter like the members of a variant.

# Generics

Let's kick things up a notch. Open up `list.urs` and you'll be greeted with
something like this:

```urs
val rev : a ::: Type -> list a -> list a
```

I think looking at the implementation might make it a bit easier on the eyes,
so let's pull it up for a moment before going back to its signature.

```ur
fun rev [a] (ls : list a) = ...
```

The `a` in square brackets here corresponds to `a ::: Type` in the signature
above. We could also write it like `[a ::: Type]` if we wanted to be more
explicit.

As you might have guessed, `a` is an explicit type parameter that ensures
`rev` is polymorphic. OCaml also has [a similar syntax][ocaml-poly] for
ensuring the well-typedness of a polymorphic function, but while expliciting
the polymorphic type parameters might be optional in OCaml, it is
not in Ur/Web.

Quoting from the [tutorial](http://www.impredicative.com/ur/tutorial/intro.html):

> Unlike in ML and Haskell, polymorphic functions in Ur/Web often require full
> type annotations. That is because more advanced features make Ur type
> inference undecidable.

Let's look at `List.mp` (which is just the `List.map` function, but it can't be
called `map` because `map` is a keyword in Ur/Web).

```urs
val mp : a ::: Type -> b ::: Type -> (a -> b) -> list a -> list b
```

`mp` has two polymorphic type parameters, so they are both made explicit in
the signature.

Interestingly, we can write a function so that the type parameter has to be
passed **explicitly** by replacing the triple colon (`:::`) with a double colon
(`::`):

```ur
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

# Basics of type constructors

At this point I should introduce type constructors, because they can do
a lot more than those in other languages. Open up `json.ur` (not `json.urs`)
and the first thing you'll see will be this:

```ur
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

Remember what I said earlier about unifying function application and type
constructor application? As it turns out, **type constructors are actually
type-level functions**, and the purpose of this unification is just to make
this similarity more apparent.

This insight will not net you much in OCaml or SML because type constructors
have a lot of limitations compared to functions: they can't be curried, and
you can perform very few operations on them.

Ur/Web's type constructors don't have these limitations. In fact, the `json`
declaration above is actually syntactic sugar for a type-level function:

```ur
con json = fn (a :: Type) =>
  {ToJson : a -> string,
   FromJson : string -> a * string}
```

We can define a **curried** constructor that takes two types and returns the
type of a 2-tuple:

```ur
con pair a b = a * b

con intAnd :: Type -> Type = pair int

val p : intAnd string = (451, "what a shame")
```

We can also perform various useful operations on record types, as we'll see
later.

# Type classes

Ur/Web's `=` (equals) operator works just like you'd expect it to for types
provived by the standard library: `1 = 1`, `"line" = "line"`,
and `Some "just" = Some "just"`. So is it implemented like in [OCaml][ocaml-eq],
using a "magic" internal function that structurally compares record fields
and variant members? Not quite.

If we try to compare two records, we'll get a surprisingly helpful error
message:

```ur
(* test.ur *)
val ok = { A = 1 } = { A = 1 }

(* test.ur:1:5: (to 1:26) Can't resolve type class instance
   Class constraint: eq {A : int} *)
```

Let's take a look into `basis.urs`. At line 26, you'll see these declarations:

```urs
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

In this case we can't look at its implementation because `Basis` is implemented
in C, but it would look somewhat like this:

```ur
con eq t = t -> t -> bool
```

So now we should have all the pieces to understand the `eq` function above.
Or do we?

If you were to define your own `eq` constructor and your own `eq` function,
you'd always have to pass a function of type `eq t` as first argument (also
called *witness*):

```ur
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

Turns out that the `eq` function is just the desugared name of the `=`
operator, and we used it above without having to worry about the witness
function. This is where the `class` keyword comes into play.

When we mark `eq` with the `class` keyword in a signature file, the compiler
will automatically search for a fitting implementation of `eq t` every time we
call `=` with a given `t`.

The `option` constructor also defines an `eq` witness in  the `Option` module.
This is its signature:

```urs
val eq : a ::: Type -> eq a -> eq (option a)
```

This should be straightforward by now. But how is it implemented?

```ur
fun eq [a] (_ : eq a) = ...
```

Even though we might not actually use the witness function, Ur/Web still
requires us to specify it in the implementation, hence the wildcard. This
argument can also be called a **constraint** on `a`.

Now the error message should make sense: the compiler is telling us that the
`=` function has a constraint of type `eq {A : int}` on its arguments, so we
need to implement `eq` for `{A : int}`. Since `eq` is an opaque type, we need
to use the `mkEq` function to do this.

```ur
val eq_a_int = mkEq
  (fn (a : {A : int}) (b : {B : int}) =>
    a.A = b.A)

val ok = { A = 1 } = { A = 1 }
```



[stdlib]: https://github.com/urweb/urweb/tree/master/lib/ur
[reason-params]: https://reasonml.github.io/docs/en/comparison-to-ocaml#type-parameters
[ocaml-poly]: https://blog.janestreet.com/ensuring-that-a-function-is-polymorphic-in-ocaml-3-12/
[ocaml-eq]: https://blog.janestreet.com/the-perils-of-polymorphic-compare/
[ocaml-abstract]: https://caml.inria.fr/pub/docs/manual-ocaml/moduleexamples.html#sec20
