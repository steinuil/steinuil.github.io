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

Though, to its credit, they also concede that _one could go further and
abstract upon the type `string` of tokens_. Still, I found surprisingly little
on the topic of parsing streams of things other than characters, or even
semi-structured data, using parser combinators, so I thought I'd share what I
stumbled upon.

---

In one of my projects I have to parse the XML specification of the X11
protocol into an AST (which I use to generate X11 bindings). While I do have
a simple version written in recursive descent style, it's kind of an eyesore,
so I spent a lot of time thinking about how to improve it.

[Xmlm](https://erratique.ch/software/xmlm), the library I'm using to parse
XML, has a streaming API that emits chunks of XML like a lexer instead of
parsing the whole file and giving it back to you inside a tree data structure.
There's a simplified interface built on top of the streaming one that does
just that though, and that's what I was using in the recursive descent parser.



[Xmlm](https://erratique.ch/software/xmlm) is the library I'm using to parse
XML. Its API is particular because instead of parsing the whole XML file and
giving it back to you in a tree data structure, it instead emits a sequence
of _signals_ in a specific order, kind of like a lexer.

```ocaml
type signal =
  [ `Dtd of dtd
  | `El_start of tag | `El_end
  | `Data of string ]
```

There's no recursion in the data type; constructing trees is up to the user
of the API. For `<a><b>c</b>d</a>` you'll get this sequence:

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

For the recursive descent parser I used the "simple" API which just reads the
sequence into a tree like a normal XML parser, but I've always wanted to use
the streaming API. 









I found surprisingly little literature on this topic of parsing semi-structured
data formats into more structured data, so I thought I'd share what I stumbled
upon.

In one of my projects I have to parse the XML specification of the X11
protocol into an AST so that I can generate some code from them. I found
surprisingly little literature on the topic of parsing semi-structured data
formats into structured data, so the first time I just went with a classic
recursive descent approach. Not happy with the result, I rewrote it using the
same approach, and lo and behold, it still sucked. I gave up trying to improve
it after attempting a third rewrite.

But lately I've had a realization. Back when I was using Elm I wrote a lot of JSON decoders using , whose API bears an uncanny
resemblance to the parser combinator library I started using on another
project. So I came up with some stuff.

```ocaml
val el : string -> (Xmlm.attribute list -> 'a)
  -> 'b parser -> ('a * 'b) parser
val data : string parser
```





Then I had a realization. While learning how to use parser combinators on
another project I started noticing an uncanny resemblance to
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


[elm-json]: https://package.elm-lang.org/packages/elm/json/latest/
