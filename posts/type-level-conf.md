# Configuration permutations in the type system where they belong

Suppose we're maintaining a frontend application. This application has to work
across different sites, each identified by a triplet of name, language and country.
Let us have a type for that.

```typescript
interface Site {
  name: string;
  language: string;
  country: string;
}
```

Our coworker Homer passes by and looks at our code.

This is good enough, he might say, and we know he's wrong. We have a list of all the
site names and supported locales ready to be used. What the hell is a string?, you ask him.
Is the empty string a valid site name? Is "dddsdsddddssddsdsd" a valid language?
Is Wales a country? Does the pope shit in the woods?

```typescript
type SiteName = "scylla" | "charybdis";
type Language = "it" | "de" | "el" | "hr";
type Country = "IT" | "CH" | "GR" | "HR";

interface Site {
  name: SiteName;
  language: Language;
  country: Country;
}
```

Only there's a catch: not all sites support all locales, and not all locales are valid.
In fact we have a list of all the possible permutations of these three parameters.
I have it on good authority that people in Italy don't speak Greek, and yet the type of
`Site` says otherwise. How can we sleep at night knowing that one day Homer could just
wake up and go add a site with locale `el_IT`?

```typescript
type SiteName = "scylla" | "charybdis";
type Language = "it" | "de" | "el" | "hr";
type Country = "IT" | "CH" | "GR" | "HR";

interface S<N extends SiteName, L extends Language, C extends Country> {
  name: N;
  language: L;
  country: C;
}

type Site =
  | S<"scylla", "it", "IT">
  | S<"scylla", "el", "GR">
  | S<"scylla", "hr", "HR">
  | S<"charybdis", "de", "CH">
  | S<"charybdis", "it", "CH">
  | S<"charybdis", "hr", "HR">;
```

Now we have an issue: if we were to add a new language, say "fr", we'd have to add it
in two places, and too much typing is bad for your wrists. Let us reduce the risk
of carpal tunnel.

```typescript
interface S<SiteName, Language, Country> {
  name: SiteName;
  language: Language;
  country: Country;
}

type Site =
  | S<"scylla", "it", "IT">
  | S<"scylla", "el", "GR">
  | S<"scylla", "hr", "HR">
  | S<"charybdis", "de", "CH">
  | S<"charybdis", "fr", "CH">
  | S<"charybdis", "it", "CH">
  | S<"charybdis", "hr", "HR">;

type SiteName = Site["name"];
type Language = Site["language"];
type Country = Site["country"];
```

Much better. Our wrists rejoice.

Now suppose we have a feature that we only want to see on scylla, so we only want to handle
the locales that are supported on scylla. TS defines a utility types that does just that
called `Extract`, so let us define some utility types for that.

```typescript
type SitesByName<N extends SiteName> = Extract<Site, { name: N }>;

type _1 = SitesByName<"scylla">["country"]; // "IT" | "GR" | "HR"
```

We also want to have a string representation of each site, so we can use it as key in
an object for features that have a different behavior on each sites. This is a bit boilerplatey,
but sadly necessary.

```typescript
type SiteString =
  | "scylla|it_IT"
  | "scylla|el_GR"
  | "scylla|hr_HR"
  | "charybdis|de_CH"
  | "charybdis|fr_CH"
  | "charybdis|it_CH"
  | "charybdis|hr_HR";
```

We also need some function to convert a `Site` to and from a `SiteString`, but if we
were to do it with just these types we'd be losing precious type information in the
process! We surely don't want that. We need some sort of conversion table.

```typescript
interface SiteOfString {
  "scylla|it_IT": S<"scylla", "it", "IT">;
  "scylla|el_GR": S<"scylla", "el", "GR">;
  "scylla|hr_HR": S<"scylla", "hr", "HR">;
  "charybdis|de_CH": S<"charybdis", "de", "CH">;
  "charybdis|fr_CH": S<"charybdis", "fr", "CH">;
  "charybdis|it_CH": S<"charybdis", "it", "CH">;
  "charybdis|hr_HR": S<"charybdis", "hr", "HR">;
}

type SiteString = keyof SiteOfString;

type _2 = SiteOfString["scylla|hr_HR"]; // S<"scylla", "hr", "HR">
```

Once again we can derive the union we wrote above from this table to save us a bit of typing.
We still need to be very careful to keep `Site` and `SiteOfString` in sync, because
debugging a type error deriving from one of those could easily get confusing.

Now let us implement the function to parse a `SiteString` into a `Site`.

**Content warning: unsafe type assertions**

```typescript
export const parseSiteString = <SS extends SiteString>(
  siteString: SS
): SiteOfString[SS] => {
  const [, name, language, country] = siteString.match(
    /([a-z]+)\|([a-z]+)_([A-Z]+)/
  )! as any[];
  return { name, language, country };
};

parseSiteString("scylla|hr_HR"); // S<"scylla", "hr", "HR">
```

The two assertions make us sick to the stomach, but after adding a few tests we feel better enough
to move onwards. Seeing the function convert the string with 0 type information loss really is its
own reward. A pleasure Homer will never understand.

The reverse is a bit trickier, but fortunately the very nice [typelevel-ts](https://github.com/gcanti/typelevel-ts)
library already has a similar type we can look up to help us on our journey to enlightenment, namely `KeysOfType`.

> `KeysOfType`: Picks only the keys of a certain type

```
export type KeysOfType<A extends object, B> = { [K in keyof A]-?: A[K] extends B ? K : never }[keyof A]
```

Let us adapt it for our use case.

```typescript
export type StringOfSite<S extends Site> = {
  [K in SiteString]: SiteOfString[K]["name"] extends S["name"] ? K : never
}[SiteString];

type _3 = StringOfSite<S<"scylla", "hr", "HR">>;
// "scylla|it_IT" | "scylla|el_GR" | "scylla|hr_HR"
```

But that only returns the `SiteString`s with the same name, you hear behind you.
Patience, Homer. Design is an iterative process, and so let us iterate on the result
of this first type with the other two parameters.

```typescript
export type StringOfSite<S extends Site> = {
  [K in SiteString]: SiteOfString[K]["name"] extends S["name"]
    ? SiteOfString[K]["language"] extends S["language"]
      ? SiteOfString[K]["country"] extends S["country"]
	    ? K
		: never
      : never
    : never
}[SiteString];

export const serializeSite = <S extends Site>({
  name,
  language,
  country
}: S) => `${name}|${language}_${country}` as StringOfSite<S>;

serializeSite({ name: "charybdis", language: "de", country: "CH" });
// "charybdis|de_CH"
```

That'll do, pig. That'll do.

---

You probably shouldn't use this kind of type-level hackery on a production application.
But you might get away with it if you use a type-level testing library like 
[dtslint](https://github.com/Microsoft/dtslint) or
[conditional-type-checks](https://github.com/dsherret/conditional-type-checks).

Here's the full source code, ready to be pasted in your editor or on
[TypeScript's playground](https://www.typescriptlang.org/play/index.html).

```typescript
interface S<SiteName, Language, Country> {
  name: SiteName;
  language: Language;
  country: Country;
}

type Site =
  | S<"scylla", "it", "IT">
  | S<"scylla", "el", "GR">
  | S<"scylla", "hr", "HR">
  | S<"charybdis", "de", "CH">
  | S<"charybdis", "fr", "CH">
  | S<"charybdis", "it", "CH">
  | S<"charybdis", "hr", "HR">;

type SiteName = Site["name"];
type Language = Site["language"];
type Country = Site["country"];

type SitesByName<N extends SiteName> = Extract<Site, { name: N }>;

interface SiteOfString {
  "scylla|it_IT": S<"scylla", "it", "IT">;
  "scylla|el_GR": S<"scylla", "el", "GR">;
  "scylla|hr_HR": S<"scylla", "hr", "HR">;
  "charybdis|de_CH": S<"charybdis", "de", "CH">;
  "charybdis|fr_CH": S<"charybdis", "fr", "CH">;
  "charybdis|it_CH": S<"charybdis", "it", "CH">;
  "charybdis|hr_HR": S<"charybdis", "hr", "HR">;
}

type SiteString = keyof SiteOfString;

export const parseSiteString = <SS extends SiteString>(
  siteString: SS
): SiteOfString[SS] => {
  const [, name, language, country] = siteString.match(
    /([a-z]+)\|([a-z]+)_([A-Z]+)/
  )! as any[];
  return { name, language, country };
};

export type StringOfSite<S extends Site> = {
  [K in SiteString]: SiteOfString[K]["name"] extends S["name"]
    ? SiteOfString[K]["language"] extends S["language"]
      ? SiteOfString[K]["country"] extends S["country"] ? K : never
      : never
    : never
}[SiteString];

export const serializeSite = <S extends Site>({
  name,
  language,
  country
}: S) => `${name}|${language}_${country}` as StringOfSite<S>;
```
