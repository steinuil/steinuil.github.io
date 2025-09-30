+++
title = "Types of parser combinators"
date = 2021-11-16
aliases = ["/molten-matter/types-of-parser-combinators"]

[taxonomies]
tags = ["parser-combinators"]
+++

I've been trying to write this post for a long while. Parser combinators to me are a Leitmotiv that plays whenever I need to parse something and the times look dire. Every time I almost forget they exist, and every time a light will go off inside my head and I'll think, "I know! I'll use parser combinators!"

Parser combinators are a universally useful concept. They're like parsley, because they go well with any sort of data that you might wanna throw at them. And yes, parser combinators [_are_ like burritos](https://blog.plover.com/prog/burritos.html).

Let me explain myself.

## You have a parsing problem

As you do, because what programs do is transform data, and you only have one hammer, and so all programs are compilers. Usually this involves consuming less-structured input and producing more-structured output. [This is called parsing](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/), and this is why you have a parsing problem.

This input could be a _stream_ of things, be it characters, bytes, or tokens, or it could be a _tree_ of things, be it a hash table, the AST of a program, JSON, HTML, s-expressions, or any sort of arborescent structure you might think of. What a parser does, then, is to take that structure, or maybe just part of it, and make sense of it. Sometimes it doesn't make sense, and in that case we want to return an error. We can turn this into a type:

```typescript
type Output<T> = {
  value: T;
  rest: Input | null;
};

type Parser<T> = (i: Input) => Result<Output<T>, Error>;
```

In other words, a parser is a function that takes some input data and returns either some more-structured data with or without the rest of the input depending on the parser, or an error, if the data doesn't make sense.

## Hot parsers in your area

So what are some things that are parsers? [`JSON.parse`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse) is an obvious parser. It fully consumes its input and throws an error if it doesn't make sense, or if there's trailing data.

```
>> JSON.parse("123")
<- 123
>> JSON.parse("")
<- Uncaught SyntaxError: ...
>> JSON.parse("123asd")
<- Uncaught SyntaxError: ...
```

[`parseInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt) is another obvious parser, one with confusing semantics and a few footguns. `parseInt` accepts trailing data and returns `NaN` when the input doesn't make sense.

```
>> parseInt("123")
<- 123
>> parseInt("0x7b")
<- 123
>> parseInt("123asd")
<- 123
>> parseInt("asd")
<- NaN
```

[`RegExp#exec`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/exec) is also a parser. This one can return multiple outputs, and the match also doesn't have to start right at the beginning of the input.

```
>> const matchB = (str) => str.match(/b/);
>> const match = matchB("abc");
<- Array ["b"]
>> match.index
<- 1
```

But we can go deeper. Indexing an array can also be called a parser, one that doesn't return the rest of the input and returns `undefined` on error.

```
>> const first = (array) => array[0];
>> first([1, 2, 3])
<- 1
>> first([])
<- undefined
```

By this logic, `Array#find` could also be used to construct a parser. This one also doesn't return the rest of its input and returns `undefined` on error.

```
>> const findEven = (array) =>
  array.find((n) => n % 2 === 0);
>> findEven([1, 2, 3, 4])
<- 2
>> findEven([1, 3, 5])
<- undefined
>> findEven([])
<- undefined
```

But it's not only lists of data that can be parsed. Object indexing is also parsing!

```
>> const getNestedItem = (o) => o?.a?.b?.c;
>> getNestedItem({ a: { b: { c: 1 } } })
<- 1
>> getNestedItem({})
<- undefined
```

Other examples could be `String#slice`, `Set#has`... The list could go on.

These functions don't exactly match the signature of the `Parser` we defined above, but they match the _spirit_. Take something, apply some logic to make sense of it, and return either an output that tells you something about that input, or an error.

## Ok, so?

You've done well to make it this far, but I'm sure you, hypothetical reader #1 who lurks all the colored websites and has already seen countless posts about parser combinators, know all about parser combinators. You know the `char` parser and you know the `string` parser and you might even know the `regexp` parser. You might also know some variation of the `token` parser and the `byte` parser and maybe you've even given [nom](https://docs.rs/nom/5.0.0/nom/) a try.

And I'm sure you, hypothetical reader #2 who has just read the paragraph above and has no idea what I'm talking about, have some questions. To you I recommend reading [You could have invented parser combinators](https://www.theorangeduck.com/page/you-could-have-invented-parser-combinators), an excellent post that might give you an intuition for understanding parser combinators, and then coming back to this post.

Knowing all that you might be wondering, what's the point of this post? Do we really need _yet another_ parser combinator post? Searching "parser combinators" yields tens, even hundreds of posts, tutorials, books, libraries, and so on. I'm not sure there's as many as there are monad tutorials, but it looks close enough to me.

I would be inclined to agree with you; I've read a few dozen of these posts, and I see them pop up on the colored websites every now and then. I don't even click on them anymore because they mostly say the same things in a slightly different sauce.

However, I would still urge you to read on, firstly because this is _my_ parser combinators blog post and there are many like it but this is mine, and secondly because I don't think I've seen this specific bit of insight in any of the aforementioned blog posts. Ready?

## Parser combinators can parse much more than strings and bytes

You might have noticed that I added object indexing as a form of parsing. This is one of the key components of Elm's [Json.Decode](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode) module. Rescript also has [a similar library](https://github.com/nkrkv/jzon). That's right, you can parse JSON with parser combinators, and I don't mean deserializing a string into a JSON tree; I mean turning a JSON tree into typed data that you can actually work with.

This is not much of an issue in TypeScript because `JSON.parse` returns `any` and that means it will just trust you that whatever data it just parsed has the shape you told it would. But that's not really parsing, that's an unsafe type cast!

[Elm](https://elm-lang.org/) aims to be a language with no runtime exceptions, and it achieves that goal by not trusting anything that comes from the outside world; if you want to query an external API that speaks JSON, you'll have to _parse_ that untrusted JSON data into an Elm record using a `Decoder`.

This is what a decoder for a simple JSON object with two fields looks like.

```elm
type alias User =
  { name : String
  , age : Int
  }

userDecoder : Decoder Info
userDecoder =
  map2 User
    (field "name" string)
    (field "age" int)
```

Elm doesn't outright call them that because it's afraid of complex terminology, but `map2` and `field` are parser combinators. They're functions that take parsers as arguments and return another parser that combines them in some way. If you take a careful look at the `Json.Decode` documentation you'll find all the usual suspects: list, dict, field, maybe, oneOf, all the map functions, andThen, etc. are all names you're probably familiar with if you've worked with parser combinators.

So what's the difference between this and most other parser combinator libraries out there? Well, the combinators are mostly the same, but the building blocks are different. JSON contains simple fields like booleans, numbers, and strings, but also ordered collections (arrays) and unordered key-value collections (objects), so the simple `char` parser won't help much here.

To parse all this nonsense, `Json.Decode` provides different base parsers. There's one for each of the JSON data types: `string`, `bool`, `int`, `float`, `list`, and `dict`. Then it provides `field`, which pulls a value out of an object by name, and `index`, which pulls an item out of an array by index.

The rest of the combinators are mostly the same as in stream-based parser combinators, which leads me to another one of my points.

## There can be different types of parsers

I think the main difference between a parser that consumes streams of items, such as a string, and a parser that consumes an unordered key-value collection, such as a JSON object, comes down to how you answer this question: _how do you pull a value out of that collection?_

The answer varies depending on a few factors:

- Is the collection ordered or unordered?
- Can the collection be indexed by a key?
- Can the keys be enumerated?
- Can the keys be sorted?

Let's see how some basic data structures fare with these questions:

- **Streams** are ordered but cannot be indexed, so to pull out a value we can only _advance_ them.
- **Sets** are unordered and can be indexed, but the keys can't be enumerated, so to pull out a value we can only _index_ them using a key.
- **Structs** (or objects) are unordered but can be indexed, so we can _index_ them easily, but since the keys can be enumerated and they can be sorted we could also come up with a way to _advance_ them.
- **Arrays**, **strings** and **tuples** are ordered, they can be indexed, and keys can be enumerated since they have a fixed length, so we can either _advance_ or _index_ them.
- **Tagged unions**, or variants, discriminated unions, sum types or whatever you might wanna call them, are similar to streams but they only contain one element, so technically we can advance them, but we can only do it once and there's gonna be several functions we can use to advance, typically one for each case of the union like in Elm's `Json.Decode`. I'm calling this action _consume_, but we could also view it as a special case of _advance_.

To sum up, these are the different types of basic parsers we have identified:

- **Consume**-type parsers operate on the full input. The pull function takes the full input and only returns an output. Some examples are JavaScript's `JSON.parse`, or the basic parsers in Elm's `Json.Decode`.
- **Advance**-type parsers operate on a stream of data. The pull function takes the input and returns both the output and the next input. If the input is _fully consumed_, the next input is empty. The basic parsers in most parser combinator libaries fall under this category.
- **Index**-type parsers operate on a collection of data that can be indexed. The pull function takes both the input and an index as arguments, and returns the output. These kinds of parsers can decide whether they want to consume the input and return the next input along with the output, or leave the input untouched. Some examples are indexing an array or an object, or the `field` parser in Elm's `Json.Decode`.

Depending on the type of parser you're using, some combinators may or may not be applicable. For example, sequencing combinators don't make sense in consume- and index-type parsers. Some basic parsers such as `any` also cannot be implemented in index-type parsers because the pull function requires an index to be passed to it.

Looking back at Elm's `Json.Decode` we can see that it uses both consume- and index-type parsers, one for parsing single JSON values and the other for parsing JSON objects, so all of these kinds of parsers can coexist with each other when parsing complex nested data.

## Thoughts

I decided to finally write this post because I've been working on parsing the game files of the iOS version of Kamaitachi no Yoru, one of the first "sound novels", which is a fancy name for a text CYOA game with some graphics and sound and music. The files are just HTML and JS, and I _could_ just slap them into a web browser and do some hacks to get them working (which I sort of did already), but it's much more interesting to parse them into a declarative format and do some fancy analysis on them. I could do some nice stuff like preload the next page's background image and music, and some fancy stuff like adding an in-game flowchart like some of the other ports of Kamaitachi no Yoru did. I was getting a bit bored writing a recursive descent parser for this and then I remembered about parser combinators, so there you have it.

This post is a brain dump of all the stuff I've been thinking about while writing other parser combinators in the past. I wrote [one that consumes streaming XML](https://github.com/steinuil/xobl/blob/main/patche/xml.ml) and [another one for JSON](https://github.com/steinuil/nene/blob/master/patche/json.ml) and I thought they turned out pretty well, but figuring out how to classify and compose them required some more thinking, and this is it.

If you were expecting an implementation of all these things I just wrote about, too bad! Maybe I'll write another post about it when I'm done writing the parser for these game files.

If you were expecting the announcement of a library of sorts, too bad! I don't know if I have it in me to write a generally useful implementation of this. I'll probably just write what I need for parsing those game files and forget about it. I'm not a library-writing kinda person.

I'm sure somebody else already thought of this stuff but I haven't seen much about it on the internet, do tell me if you know of anything else. I've seen that F#'s [XParsec](http://xparsec.corsis.tech/) already implements some of this stuff but that's about it. [Hutton and Meijer (1996)](https://www.cs.nott.ac.uk/~pszgmh/monparsing.pdf) also mentions that _"One could go further (as in ([Hutton, 1992](http://www.cs.nott.ac.uk/~pszgmh/parsing.pdf)), for example) and abstract upon the type String of tokens"_, I haven't read Hutton 1992 yet but I guess I should.

