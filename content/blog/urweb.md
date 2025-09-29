+++
title = "I survived Ur/Web"
date = 2018-01-22
+++

I don't remember when it was that I first tried [Ur/Web][urweb], but I'm sure I
didn't last long with it. As soon as I strayed a bit from the examples provided
on the website (seemingly the only documentation available), I would hit a brick
wall, in the form of unreadable compiler errors. I got so frustrated that I
deleted all the files I was working on and the compiler with them, and I didn't
touch the language for a while.

I'd try again after a few months, once again lured in by the
ludicrous promises listed on the front page of the website: no more complex
ORMs, no more crappy templating languages, no more brittle internal APIs, and
all of this packaged up in a neat ML-like language with a solid and powerful
type system that compiles down to very efficient C code. It was too good to be
true, and I wanted into it. Soon enough I'd hit another brick wall and the
cycle would repeat itself once again, until I got to the point where I was
confident enough in the language that I could write it for a few hours without
getting stuck too much.

As it turns out, my frustration with it is one of the language's many features.
In the age of languages like Elm and Go, which jeopardize sophistication to
appeal to the newcomers, Ur/Web takes Haskell's motto of avoiding success at
all costs and runs with it. [In the words of the language's creator][adoption]:

> I also want to emphasize that I'm not trying to maximize adoption of
> Ur/Web.  Rather, I'm trying to maximize the effectiveness of people who
> do choose to use it.  This means that I'm completely happy if basic
> features of Ur/Web mean that 90% of programmers will never be able to
> use it.

Seen from this perspective, everything starts falling into place. The homepage
straight from the late 90s, the few examples and the TeX-formatted PDF manual,
the lack of any sort of documentation to the standard library that doesn't
involve digging through the scantly commented signature files. **It's all
intended.**

Jokes aside, while I do find the approach to language design admirable, I think
the ecosystem could use a lot of improvement; at the very least some more
comments in the stdlib signature files and possibly some way to generate an
HTML page out of them, in the style of `ocamldoc`. I've spent enough time
trying to differentiate `queryL` and `queryL1` that I've developed a feel for
it, but I'd much rather have a thorough explaination of why they're named like
that.

The compiler also outputs errors which range from completely unhelpful parsing
errors to dozens and dozens of desugared XML and SQL statements which rival C++
template error messages in succintness and readability. As with the standard
library functions, the error messages are there to give you a feel for what the
compiler wants to see rather than to provide a useful explaination of what
happened.

## The good parts

I've only bashed the language up to now, so it's about time that I start
mentioning its good parts. Ur/Web is amazing! Part of the reason why I'm
writing this is in the hopes of getting even one other person interested in the
project, because I think it deserves more users.

It's a long and winding road to get there, but Ur/Web *does* deliver on its
promises of speeding up application development. Once you start working with
the compiler rather than against it, you'll find that you only have to worry
about the parts of your application that matter rather than getting entangled
in busywork. The compiler will not only check for mismatches in the types of
every function and value in the program like in a normal statically typed
language, but it will also check them against the database tables, cookies,
form fields and any other kind of client-server interaction; your program
simply won't compile if you query a column that doesn't exist.

Defining tables, queries, cookies and RPC becomes pretty much effortless, and
you can achieve a much higher level of "separation of concerns" through
thoughtful use of the signature files. At first I tried going for a MVC-like
approach by putting all my tables and queries in a module and all pages in
another, but after a while I found that it makes more sense to define tables
and cookies right in the modules that need them, so as not to needlessly expose
them to modules that don't. Database tables and cookies in Ur/Web are somewhat
like normal types, so you can keep them as an implementation detail of a module
or expose them as needed.

Ur/Web also compiles the client-side portions of your code to Javascript, so
you can write client code directly *in the page handler* and run the same
functions both on the server and the client (as long as they don't use any
server- or client-specific features). Reactive page generation *à la React* is
also supported through the `<dyn/>` tag, which lets you subscribe to a `source`
(basically a mutable cell, similar to `ref` in OCaml) and automatically reacts
when the source changes.  You can also push data asynchronously to a client with
`channel` and call functions that need server features without reloading the
page with `rpc` (which unfortunately doesn't support file inputs, but I'm
working on an AJAX library that will let you do that).

The language works with a transactional model which marks every function that
will have a different output even with the same inputs (e.g. a random number
generator or a database query) with the type `transaction`, and undoes any
changes that might have been made in case of an error. I had a bit of trouble
understanding the model, mostly because `transaction` is a monad and I wasn't
acquainted with the concept when I first tried the language, but after a while
it became useful and natural to wall off the effectful functions from the rest
of the code.

## The future?

Ur/Web is far from perfect; even with a better ecosystem, documentation and
compiler messages, there's lots of things that annoy me (the "end" keyword
in `let .. in .. end` blocks, the lack of a buffer type to make string
manipulation less painful for the allocator, the lack of support for
interacting with data types more complex than strings and integers in C
bindings, ...), but it still feels like working with a language from the
future. A future where frameworks are actually compilers aware of the
application domain, and will check non-trivial properties of a program for
correctness.

That future, I think, is (or was) the end goal of the language's author, Adam
Chlipala. He seems to have envisioned Ur as a language that allows syntactic
and compiler extensions to fit any sort of application domain in a similar
manner. He looks more interested in other projects these days (though he's
still actively developing Ur/Web) so I doubt this will ever come to fruition,
but it might be a goal worth pursuing.

Eduardo Julian, the author of the
[Lux programming language](https://github.com/LuxLang/lux), gave a
[talk at StrangeLoop](https://www.youtube.com/watch?v=T-BZvBWiamU) last year
where he talked with the fervor of a madman about a similar dream of letting
users of his language implement domain-specific optimizations, core features
and compilation targets without having to change the language itself.
[Racket](https://racket-lang.org/)'s goal is to be both a general-purpose
language and a language platform, with which users can implement their own
domain-specific syntax and let it interact with normal Racket code or other
domain-specific languages. There's probably other projects with similar goals
that I don't know of, so perhaps we'll see more of this in the future.

Getting back to Ur/Web, if you like functional languages, hate the current
state of web development, can bear with the lack of documentation and
StackOverflow support, and already know a bit of Haskell/OCaml/SML, I
recommend you try it. It takes a while for it to click, but when it does it's a
wonderful experience, and you'll certainly learn something about types, MLs or
even web development in the process.

For my part, I'll try to contribute some documentation to the project to make
it a bit easier to get into the language.

## Further reading

- [Polymorphic variants in Ur/Web](http://blog.ezyang.com/2012/07/polymorphic-variants-in-urweb/)

[urweb]: http://www.impredicative.com/ur/
[adoption]: http://www.impredicative.com/pipermail/ur/2010-December/000329.html

