Who ever said that parser combinators are only for character streams? Probably
nobody, but the vast majority of parser combinator libraries and blog posts,
tutorials etc. about them only deal with characters and strings. Even the
[original paper](http://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf) by Hutton &
Meijer begins by specifying a parser as _a function that takes a **string** of
characters as input_ (emphasis mine), whose type is (liberally translated to
OCaml):

```ocaml
type 'a parser = string -> ('a * string) option
```

Though, to its credit, it also concedes that _one could go further and
abstract upon the type `string` of tokens_.

In one of my projects I have to parse the XML specification of the X11
protocol into an AST so that I can generate some code from them. I found
surprisingly little literature on the topic of parsing semi-structured data
formats into structured data, so the first time I just went with a classic
recursive descent approach. Not happy with the result, I rewrote it using the
same approach, and lo and behold, it still sucked. I gave up trying to improve
it after attempting a third rewrite.

Then I had a realization. While learning how to use parser combinators on
another project I started noticing an uncanny resemblance to
[Elm's JSON decoders](https://package.elm-lang.org/packages/elm/json/latest/),
and I thought, why does it have to be characters? Why not streams of _signals_
instead?

[Xmlm](https://erratique.ch/software/xmlm) is a streaming XML codec for OCaml.
While [xml-light](http://tech.motion-twin.com/xmllight.html) will parse the
whole XML document and give it back to you in the form of a tree data
structure, Xmlm instead gives you a stream of _signals_, which are more or
less like the tokens emitted by a lexer.

```ocaml
type signal =
  [ `Dtd of dtd
  | `El_start of tag | `El_end
  | `Data of string ]
```

The signals arrive in a specific order. For `<a><b>c</b>d</a>` you'll get this
sequence:

```ocaml
`Dtd None
`El_start ("a", [])
  `El_start ("b", [])
    `Data "c"
  `El_end
  `Data "d"
`El_end
```

(I indented the output to make the structure more clear.)

So, how can we turn this into structured data using parser combinators?
