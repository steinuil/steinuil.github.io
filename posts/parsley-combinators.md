# Parsley combinators

It is a commonly held belief<sup>[citation needed]</sup> that parser combinators can only be used to parse strings, or streams of characters, or at least that's the idea you might get by looking at most parser combinator libraries out there. Parser combinators are actually much more general and can help with parsing not only character streams, but also arbitrary streams, semi-structured data, pretty much anything you could think of.

*In Italy we say that parsley goes well with everything, much like parser combinators (when you know how to use them.)*

---

Hutton & Meijer's [seminal paper](https://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf) on parser combinators opens by defining a parser as a function that takes a *string* as input and, if successful, returns the value it parsed along with the *rest of the string*, and nothing otherwise. But it also concedes:

> One could go further (as in (Hutton, 1992), for example) and abstract upon the type String of tokens, but we do not have need for this generalisation here.

So let's do just that. This is a rather liberal OCaml translation of the parser type defined in the paper with this generalization applied:

```ocaml
type ('a, 'inp) parser = 'inp -> ('a, 'inp) option
```





## Further reading

* [XParsec](https://github.com/corsis/XParsec)