+++
title = "Enumerate your logs"
date = 2026-02-01

[taxonomies]
tags = ["gleam", "patterns"]
+++

I'm working on my Soulseek client [snus](https://kirarin.hootr.club/git/steinuil/snus) (named in honour of [nicotine+](https://nicotine-plus.org/)), which is a Gleam application targeting the BEAM and an attempt to learn some things about OTP. I've also been working on some new projects at work that use structured logging and "audit logging" using structured fields, and I like the pattern! I'd like snus to have structured logs as well. How do I do it?

## A crash introduction to Gleam

[Gleam](https://gleam.run/) is a very nice programming language with a mauve pink smiling star as a mascot. I like it a lot! I think Gleam is best described as a functional-first ML-like (as in OCaml and SML) language with a Rust-like syntax. In as few words as I can muster:

- It's expression-based and has first-class functions, generics, [variants](https://tour.gleam.run/everything/#data-types-custom-types), [opaque types](https://tour.gleam.run/everything/#advanced-features-opaque-types), pattern matching, tuples, and tail call optimization.
- It's "strongly" typed, by which I mean that every expression has a type and the only "escape hatch" is foreign function calls AKA [externals](https://tour.gleam.run/everything/#advanced-features-externals).
- In terms of syntactic conveniences it has a [pipe operator](https://tour.gleam.run/everything/#functions-pipelines), [labelled arguments](https://tour.gleam.run/everything/#functions-labelled-arguments), [flow-based record accessors](https://tour.gleam.run/everything/#data-types-record-accessors) (which sacrifice global type inference for some great syntactical convenience), a very nifty [`use` keyword](https://tour.gleam.run/everything/#advanced-features-use) that can act as a `do` operator and much more, and [binary pattern matching](https://tour.gleam.run/everything/#data-types-bit-arrays) borrowed from Erlang.
- It compiles to both Erlang and JavaScript (and has a nice [Elm-like framework for single page apps](https://hexdocs.pm/lustre/index.html)).
- It uses a `Result(t, err)` type to handle errors and it prefers `Error(Nil)` to `option.None` in cases where the failure mode is obvious, which encourages a separation of operational failure from a semantical lack of a value.
- It uses `+` for integer addition and `+.` for float addition like OCaml does, which makes me happy.

## Structured logging

Go has a [structured logging library](https://pkg.go.dev/log/slog) whose functions take an unstructured message, and then pairs of `(string, any)` as varargs. I don't remember which library my workplace uses for structured logging in Python, but I'm sure it has a similar structured.

Gleam does not have a dictionary/hash(map)/object literal: it handles dicts just like [Elm](https://package.elm-lang.org/packages/elm/core/latest/Dict). You can make a dict from a `List` of `#(key, value)` if you want, so if you wanted to reproduce `slog` in Gleam you'd have a `print(level: LogLevel, data: List(#(String, String)))` function. There's a [few](https://hexdocs.pm/glogg/index.html) [structured](https://hexdocs.pm/flash/index.html) [logging](https://hexdocs.pm/glight/index.html) [libraries](https://hexdocs.pm/gclog/index.html) on the [Gleam package index](https://packages.gleam.run/) that fit the bill, but I didn't like any of them and I was wondering how I could reconsider that approach.

Gleam doesn't have a built-in syntax for booleans; `Bool` is a "custom type" like any other that could just as easily be defined in a library:

```gleam
type Bool {
  True
  False
}
```

Booleans could just as well be reprenented as the strings `"true"` and `"false"`, but languages like Gleam and OCaml and Rust and C# and Java and Go choose to represent booleans as their own type. How many states could a `String` have compared to a `Bool`? Would you say, [ten million](https://www.youtube.com/watch?v=EWKB86iSlFo)?

Now think about your application's logs. How many states that are meaningful enough to be logged does your service have? Can you enumerate all of them? Can you gracefully handle the failures? Does the user need to know about it? Is it useful for debugging? Will the log message have to be localized at some point?

There's [several](https://hexdocs.pm/glight) [structured](https://hexdocs.pm/glogg) [logging](https://hexdocs.pm/flash) [libraries](https://hexdocs.pm/birch) [available](https://hexdocs.pm/viva_telemetry/index.html) in the Gleam package registry. Gleam is a new language whose library ecosystem is still growing, none of these libraries seem to be leading the pack, so I'm not sure I should be committing to any of them. Instead I added a `logging` module containing a `Log` variant that contains all the types of things I want to be logging in the application, along with some data that I think will be useful to debug any problems. This will let me easily switch logging implementation in the future, but I think it's also a good pattern to keep in my toolbox.

```gleam
pub type Log {
  PeerAlreadyConnected(
    conn_type: ConnectionType,
    ip: IP,
    port: Int,
  )
  PeerViolatedConnectionOrder(
    username: String,
    message: String,
  )
  // ...
}
```

Enumerating special cases in a program is a way to give them semantical meaning. I think logs can be as deserving of care and thought as much as the important part of our applications: maybe just the act of adding the failure case can give you a chance to think about it more carefully. Consider enumerating your logs.
