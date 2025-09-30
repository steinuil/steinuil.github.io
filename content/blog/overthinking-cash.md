+++
title = "Overthinking cash in TypeScript"
date = 2018-11-11

[taxonomies]
tags = ["typescript", "type-level-programming"]
+++

![cicada shells on a tree near a beach in Marina di Cecina, Italy](shells.jpg)

Part of my current project at work deals with monetary values in the form of
cash, making change, and displaying the bills and coins on the screen.

Since I recently started adding types to certain parts of the codebase with
TypeScript, I thought it'd be fun to see how elaborately I could model the
types of the values and of the functions using TypeScript's more advanced
features, and while I was at it, how easy it would be to parametrize the types
based on the currency you're dealing with.

First of all, I'm gonna define what I mean by "cash". Since I need to show
the bills and coins on the screen at scale, I need to know their color and
their dimensions, and here's the issue: coins only need a width, but banknotes
also need a height, so I can't use the same type for both.

```typescript
interface Coin<Amount> {
  amount: Amount;
  color: string;
  width: number;
}

interface Banknote<Amount> {
  amount: Amount;
  color: string;
  width: number;
  height: number;
}
```

Now I have to store these values somewhere. Using two objects, one for the
coins and one for the banknotes, would be the simplest solution, but it would
complicate things at the call site when we don't know whether the amount is
a coin or a banknote.

```typescript
const cashInfo = (amount: CashAmount): ??? => (
  amount > 200
  ? banknotesByAmount
  : coinsByAmount
)[amount];
```

This is not a very elegant piece of code, and TypeScript doesn't like it much
either.

![not even Sayaka likes it](cash-money-of-you.png)

## Dependent (kinda) types to the rescue!

TypeScript 2.8 introduced [conditional types][ts-2.8] which (as I understand it)
are a light form of dependent types, like the ones in Coq or Idris. You can use
them to implement basic arithmetic with peano numbers, which is cool as hell,
but unfortunately not very useful in real code (at least at the moment).

Now I can define a type which returns either `Coin` or `Banknote` depending
on the type of its argument:

```typescript
type ByAmount<CoinAmt, BanknoteAmt,
  Amt extends CoinAmt | BanknoteAmt
> = Amt extends CoinAmt     ? Coin<Amt>
  : Amt extends BanknoteAmt ? Banknote<Amt>
  : never;
```

Note that I'm still parametrizing over the denomination to make it possible
to use different currencies easily, so the signature still looks a bit awful,
but it'll only need one type parameter when "instantiated".

Defining the type of the object is now a breeze, thanks to mapped types.

```typescript
type CashMap<
  CoinAmt extends number,
  BanknoteAmt extends number,
  Amount extends CoinAmt | BanknoteAmt
> = {
  readonly [A in Amount]:
    Readonly<ByAmount<CoinAmt, BanknoteAmt, A>>;
}
```

Now we're ready to instantiate these types with a currency.

## Plugging in the Eurodollars

TypeScript doesn't have [polymorphic variants][poly-variants], but it does have
**numeric literal types**, which are just as good for our purposes.
Let's define the denominations.

```typescript
type EuroCoinAmt =
  1 | 2 | 5 | 10 | 20 | 50 | 100 | 200;
type EuroBanknoteAmt =
  500 | 1000 | 2000 | 5000 | 10000 | 20000 | 50000;
type EuroAmount =
  EuroCoinAmt | EuroBanknoteAmt;
```

Now I can fill in the maps.

```typescript
type EuroMap = CashMap<
  EuroCoinAmt, EuroBanknoteAmt, EuroAmount
>;

const euroByAmount: EuroMap = {
  1: {
    amount: 1,
    color: '#b87333',
    width: 16,
  },
  2: {
    amount: 2,
    color: '#b87333',
    width: 18.5,
  },
  /* ... */
  500: {
    amount: 500,
    color: 'grey',
    width: 120,
    height: 62,
  },
  /* ... */
};
```

Since this is all static data, the compiler is able to verify that:

- I didn't forget nor invent any coin or banknote
- objects indexed by a `BanknoteAmount` effectively have a `height` field,
  and that those indexed by a `CoinAmount` don't
- the indexing key matches the `amount` field

When I try indexing the object, the compiler will infer the correct type
based on the type of its argument, and complain when trying to index a value
that does not exist (though the error message for that is a bit confusing).

```typescript
euroByAmount[500]; // Readonly<Banknote<500>>
euroByAmount[2];   // Readonly<Coin<2>>

// error: Element implicitly has an 'any' type
// because type 'CashMap<EuroCoinAmt, EuroBanknoteAmt, EuroAmount>'
// has no index signature.
euroByAmount[3];
```

The advantage of keeping the more general types around is that we can now
differentiate between functions that work the same regardless of the currency,
and functions that might require a different implementation for each currency.

In my project I have a function that returns a few reasonable change suggestions
given an amount of money, in which the optimal solution is calculated using a
simple greedy algorithm. This works for euros, where the greedy algorithm does
indeed return an optimal solution, but it might not be a good fit for other
currencies with different denominations, so in this particular case it makes
sense to use the specific types for euros, rather than the more general ones.

## Conclusions

TypeScript has a rather quirky type system with many features that vaguely
resemble those found in other languages but not quite, like literal types, and
some weird features taken straight from niche almost-research languages, like
conditional and mapped types, but somehow they all fit together rather nicely
to model the sort of JS code you'd write normally.

This is TypeScript's biggest strength, in my opinion: I barely had to change
my code when adding types to this module, and it would still make sense if you
took the types out, even if I had written this in TS to begin with.

## Further reading

- [How to Handle Monetary Values in JavaScript](https://frontstuff.io/how-to-handle-monetary-values-in-javascript)
- [Money in the type system where it belongs](https://ren.zone/articles/safe-money)
- [Dinero.js](https://github.com/sarahdayan/dinero.js) - An immutable library to create, calculate and format money.

[ts-2.8]: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html
[ur-types]: http://www.impredicative.com/ur/tutorial/tlc.html
[money-js]: https://frontstuff.io/how-to-handle-monetary-values-in-javascript
[poly-variants]: https://dev.realworldocaml.org/variants.html#scrollNav-4
