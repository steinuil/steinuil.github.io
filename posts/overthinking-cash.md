Part of a project I'm working on involves handling monetary values as cash,
and since I recently started going through the trouble of converting the
codebase to TypeScript, I thought it'd be fun to see how much I could encode in
TS's quirky type system.

I decided to parametrize the types on the amounts of money, so it'd be somewhat
easy to plug in another currency.

First of all, we're gonna need to define what we mean by "coin" and "banknote".
Other than showing the amount of money they represent, I also need to display
both on the screen at scale, so I added a color, width, and height for banknotes.

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

Then we need to effectively store these values inside an object, so we can use
TypeScript's mapped types for that.
[Higher-kinded types](https://github.com/Microsoft/TypeScript/issues/1213)
unfortunately aren't yet in the language, so since we're parametrizing on the
cash amounts we can't generalize this type to a `CashMap<Amount extends number, Cash<Amount>>`
type constructor.

```typescript
type CoinMap<Amount extends number> = {
  readonly [A in Amount]: Coin<A>
};

type BanknoteMap<Amount extends number> = {
  readonly [A in Amount]: Banknote<A>
};
```

Now we can query the bills separately when we know what they are, and even
if we don't we can just ad a check at the call site to select the correct
object based on the amount.

But why stop here? `(a < 500 ? coinsByAmount : banknotesByAmount)[a]` is not an
idiom that plays very well with TypeScript, and since TypeScript 2.8 introduced
[conditional types](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html),
we can do even better. Let's define a type that returns the correct type based
on the amount.

```typescript
type ByAmount<
  CoinAmount,
  BanknoteAmount,
  Amount extends CoinAmount | BanknoteAmount
> = Amount extends CoinAmount     ? Coin<Amount>
  : Amount extends BanknoteAmount ? Banknote<Amount>
  : never;
```

And now we can define a function that takes both maps and returns the correct
bill or coin along with its correct type based on the type of the argument.
That's dependent typing! (Sort of.)

```typescript
const byAmount = <
  CoinAmount extends number,
  BanknoteAmount extends number,
  Amount extends CoinAmount | BanknoteAmount
>(
  coinsByAmount: CoinMap<CoinAmount>,
  banknotesByAmount: BanknoteMap<BanknoteAmount>,
  isBanknote: (amount: Amount) => boolean,
  amount: Amount
): ByAmount<CoinAmount, BanknoteAmount, Amount> =>
  ((isBanknote(amount)
    ? banknotesByAmount
    : coinsByAmount
  ) as any)[amount];
```

You might be feeling a bit disappointed to the cast to `any` in the actual
implementation, as did I... but it turns out that the compiler isn't actually
capable of resolving a conditional type depending on a free generic type
parameter.

You could resolve this without resorting to a cast by writing two different
function signatures, one like the one I wrote above for the interface and
another, more permissive, to type-check the implementation, but verifying
correctness in this case is trivial, so I don't feel like it's worth the effort.

# Plugging in a currency

Coming from OCaml, I imagined all of the above packaged up in a neat
parametrized module, or *functor* in ML vernacular, with which you'd only have
to implement a few values and types and you'd get back another module with all
the types and useful functions implemented automagically.

Unfortunately higher-order modules as an idiom are pretty much unheard of
outside of SML and OCaml, and so too does TypeScript ignore them.
As a result, there's a bit of boilerplate involved in actually using the
constructors I defined above with a currency.

First, we define all the denominations.

```typescript
type EuroCoinAmount = 1 | 2 | 5 | 10 | 20 | 50 | 100 | 200;
type EuroBanknoteAmount = 500 | 1000 | 2000 | 5000 | 10000 | 20000 | 50000;
type EuroAmount = EuroCoinAmount | EuroBanknoteAmount;
```

Then we can fill in the maps.

```typescriptArgument of type '3' is not assignable to parameter of type 'EuroAmount'.
const euroCoinsByAmount: CoinMap<EuroCoinAmount> = {
  1: {
    amount: 1,
    width: 16,
  },
  2: {
    amount: 2,
    width: 18.5,
  },
  ...
};
```

Note that, since I passed the indexing key (`A`) rather than the more general
type (`Amount`) as parameter to each cash type in the definition of CoinMap,
not only do I get errors for when I don't include one of the denominations in
the map, for misspells in the keys and in the `amount` fields, but even when
the value in the `amount` field does not match the indexing key:

```typescript
...
  10: {
    amount: 20,
    ^^^^^^ error: Type '20' is not assignable to type '10'.
    width: 22,
  },
```

The implementation of the `euroByAmount` function is also trivial, if a bit
verbose. Here `Amount` extends `EuroAmount` rather than the more general `number`
so we can get some additional type-checking when using the function.

```typescript
const euroByAmount = <Amount extends EuroAmount>(amount: Amount) =>
  byAmount<EuroCoinAmount, EuroBanknoteAmount, Amount>(
    euroCoinsByAmount,
    euroBanknotesByAmount,
    (a) => a > 200,
    amount
  );
```

And indeed, the function will return the correct type based on its argument,
and even fail *at compile time* when called with an amount that's not a valid
denomination!

```typescript
euroByAmount(500); // Banknote<500>
euroByAmount(2);   // Coin<2>
euroByAmount(3);
             ^ error: Argument of type '3' is not assignable to parameter of type 'EuroAmount'.
```

# A sad conclusion

Admittedly this would have worked better if TypeScript had something akin to
SML and OCaml's parametrized modules, or *functors* in ML vernacular.

Functors are a great pattern for writing code whose implementation
can easily be swapped and would fit in really well with Javascript's
module system; combined with the advanced features of TypeScript's type system
I think they would make for a really nice addition to the language.

Unfortunately functors are almost completely unheard of outside of the SML/OCaml
world, and so we're stuck with this boilerplateful jank. Sad!
