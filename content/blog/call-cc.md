+++
title = "Continuations, Promises, and call/cc"
date = 2017-10-27
aliases = ["/molten-matter/call-cc"]

[taxonomies]
tags = ["scheme", "typescript"]
+++

Say you're in the kitchen in front of the refrigerator, thinking about continuations.
You make yourself a sandwich right there and stick it on your desk.
Then you sit on your armchair and open a browser window to search for their definition.
You get a series of abstract explainations, and some examples involving fridges and
sandwiches, which leave you more puzzled than when you began.
You invoke the sandwich on your desk, and you find yourself wondering if the topic
is even worth going through all this trouble to learn about.

## Promises

Javascript has a concurrency model which can be somewhat daunting at first:
it relies on asynchronous functions, which have to be handled differently from normal ones.
If you've ever written any JS in the last few years you must've used a lot of `Promise`s,
`async`s, and `await`s, but if you haven't here's a quick reminder.

```javascript
Promise.resolve(2)
  .then(x => x + 1)
```

The value of `Promise.resolve(2)` is not quite 2, but rather a *computation* that yields 2.
The only way to increase that 2 is by passing a function to its Promise.

Javascript does this because it runs on a single thread, and making long blocking
computations (like an AJAX request) run synchronously would make the rest of the program,
and the whole page it's running on, lock up while it's waiting for that computation to finish,
and you really don't want that to happen on your website.
But try as you might, you will never be able to make that Promise return a 2,
store it in a variable and resume with your normal program flow,
like you'd do with a normal function (even though the `async`/`await` constructs adds a bit of
syntactic sugar to make handling Promises similar to normal code).

The only way to access Promised values you're left with is passing a function to their Promise
with the rest of the computations that have to performed on that value.
This style of programming is called **continuation-passing style** (CPS).

## Continuations

Simply put, the continuation to a certain value is the part of the program
that needs to wait for that value to continue execution ("the rest" of the program).

Continuations are easily represented by functions (but not quite[^1]) like the ones you
pass to a Promise.
Take a simple program `stuff() + 2`. The continuation of `stuff()` could be represented
by the function `x => x + 2`, while the continuation of `2` would be `x => stuff() + x`.

Promises can never return a value, so the only way to do something with their result is to
*reify* their continuation to a function. Reifying a continuation involves a simple rewrite
that wraps the continuation in a function taking one argument, and replaces the value
with that argument.
This rewrite is applied by many compilers as an intermediate step to simplify the language.

For example, take the classic definition of the factorial function:

```javascript
function fact(n) {
  if (n == 0) return 1;
  else return n * fact(n - 1);
}

fact(3); //=> 6
```

We could rewrite this in CPS by taking the continuation of
the tail invocation of `fact` and reifying it to a function,
then passing that function to `fact` and calling it on the result.

```javascript
function factCont(n, cont) {
  if (n == 0) cont(1);
  else factCont(n - 1, x => cont(n * x));
}

factCont(3, console.log); //=> 6
```

If you pass two functions to it, one representing success and the other failure,
you have Promises! (without the asynchronicity.)

For more a more thorough explaination and some advantages of this style, I recommend
[Matt Might's](http://matt.might.net/articles/by-example-continuation-passing-style/)
[posts](http://matt.might.net/articles/programming-with-continuations--exceptions-backtracking-search-threads-generators-coroutines/)
on the topic.

## call/cc

The problem with CPS is that nobody in their right mind would willingly write their code
like this. Most languages offer a few constructs that have similar effects to some of
the uses of explicit continuations, such as early returns, exceptions, gotos, or async/await.
Others, like Scheme, SML and [Ruby](https://ruby-doc.org/core-2.4.1/Kernel.html#method-i-callcc),
give you first class access to raw undelimited continuations through a
construct called *call-with-current-continuation*, abbreviated to `call/cc`
or `callcc`.

call/cc takes a function of one argument, and calls it with the current (relative to
where call/cc was called) continuation as its argument (historically called `k`).
Invoking `k` with a value, also referred to as "throwing", will set the
continuation to that value, thus emulating an early return.

```lisp
(call/cc
  (lambda (return)
    (display 'before)
    (return)
    (display 'after)))
; => before
```

Storing the current continuation in a mutable cell allows one to return to that point in
the program from anywhere else, in a way that's similar to gotos or C's `setjmp`/`longjmp`.

```lisp
(define counter #f)

(let ((x 0))
  ((lambda ()
     (call/cc (lambda (k) (set! counter k)))
     (set! x (+ 1 x))))
  (display x))
; => 1
(counter) ; => 2
(counter) ; => 3
```

Combining these two cases, one can implement even more complex and convoluted control
flow structures, like exceptions, coroutines, or logic programming-style backtracking.
The implementations are <s>a pain to write so I left them out</s> left as an exercise to
the reader.

There have been a number of [points](http://okmij.org/ftp/continuations/against-callcc.html)
raised against call/cc and first-class access to undelimited continuations, many
of which propose *delimited* continuations as a cleaner, less costly alternative,
but I'll be taking a look at those in a later post.

## Sandwiches

Getting back to the sandwich example (or sand-witch, as [the author of this quote](https://groups.google.com/forum/#!msg/perl.perl6.language/-KFNPaLL2yE/_RzO8Fenz7AJ)
stubbornly calls it):

> Say you're in the kitchen in front of the refrigerator, thinking about a
> sandwitch.  You take a continuation right there and stick it in your
> pocket.  Then you get some turkey and bread out of the refrigerator and
> make yourself a sandwitch, which is now sitting on the counter.  You
> invoke the continuation in your pocket, and you find yourself standing
> in front of the refrigerator again, thinking about a sandwitch.  But
> fortunately, there's a sandwitch on the counter, and all the materials
> used to make it are gone.  So you eat it. :-)

It becomes obvious once you translate it to code:

```lisp
(define (eat-sandwich sandwich)
  (display "burp"))

(let ((pocket #f)
      (fridge '(turkey bread))
      (counter '()))
  ; in front of the refrigerator
  (call/cc (lambda (k) (set! pocket k)))
  (if (and (empty? counter) (not (empty? fridge)))
    (let ((sandwich (cons (car fridge) (cadr fridge))))
      (set! fridge '())
      (set! counter (list sandwich))
      (pocket))
    (eat-sandwich (car counter))))
; => burp
```

The program saves its continuation. Then it checks if there's anything on
the counter and, finding nothing, it makes the sandwich and invokes the
previously saved continuation, returning to the beginning of the conditional.
This time it finds a sandwich in the counter, so it can start eating.

Lucky bastard. It gets to travel back in time, while I'm left here writing posts
that the past me will never get a glimpse of.

[^1]: It is important to remember that undelimited continuations are not proper functions, because they cannot in any case return a value: in a typed language aware of continuations, a continuation would have a return type equivalent to [TypeScript's `never`](http://www.typescriptlang.org/docs/handbook/basic-types.html#never), or a type annotation like [C's `_Noreturn`](http://en.cppreference.com/w/c/language/_Noreturn). See [Oleg Kiselyov's explaination](http://okmij.org/ftp/continuations/undelimited.html) for more information on this.

