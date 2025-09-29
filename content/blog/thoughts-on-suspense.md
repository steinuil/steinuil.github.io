+++
title = "Thoughts on Suspense for data fetching"
date = 2019-10-30
+++

React's [Concurrent Mode](https://reactjs.org/docs/concurrent-mode-intro.html) has finally
landed in React's experimental builds, and it just so happens that I have to start writing this
new app at work to be used internally, so what better way to get my hands dirty with this new
shiny stuff!

[In another post](/molten-matter/data-fetching-react/) I expressed some disconcert at what little
I remembered of Suspense's API (kinda missed that .read() thingy in the fetch request), and that...
is still there after seeing the full API. I think you'll see what I mean.

## Exceptions for control flow

I happen to have here a sort of minimal working example of "Suspense for data fetching".

```tsx
const Hello = ({ resource }) => (
  <span>Hello {resource()}</span>
);

const SuspendTest = () => {
  const resource = suspendPromise(async () => {
    await sleep(3000);
    return "from inside a shell";
  });

  return (
    <Suspense fallback="loading...">
      <Hello resource={resource} />
    </Suspense>
  );
};
```

- This will display "loading..." for 3 seconds and then show "Hello from inside a shell"
- `sleep` is `(ms) => new Promise((resolve) => setTimeout(resolve, ms))`
- We'll call "resource" the thing that provides our `Hello` component with the data it needs to render

The resource is clearly a promise but you don't have to await it; you just call it as if you already
had the data inside it. How the hell does this work? The title of this section kinda spoiled it,
but here it is anyway:

```typescript
export function suspendPromise<T>(thunk: () => Promise<T>) {
  let state = { status: "PENDING" };

  const pendingPromise = (async () => {
    try {
      state = { status: "SUCCESS", data: await thunk() };
    } catch (e) {
      state = { status: "ERROR", error: e };
    }
  })();

  return () => {
    switch (state.status) {
      case "PENDING":
        throw pendingPromise;
      case "ERROR":
        throw state.error;
      case "SUCCESS":
        return state.data;
    }
  };
}
```

It fires the promise and then returns a function that will fetch the data, if it's available.
And if it's not, it just *throws the promise*. That's it, that's the magic. `Suspense` then will
act like an [error boundary](https://reactjs.org/docs/error-boundaries.html) and catch the promise
and then do whatever it is that it does to promises. Presumably await them and then retry with
the rendering roughly when they're done.

This is the part where I pretend to know what algebraic effects are and say, gosh, this looks a lot
like algebraic effects.

I grew to like fetching in useEffect, but I won't deny it's always looked a bit awkward, so I'm glad
this deprecates it. I'm also glad this makes the API synchronous, because it means that error
boundaries are finally useful. To be frank, I haven't implemented error handling in the data-fetching
component I use in another app because if the request returns an error it can only mean the server
is down, and that's a scenario I don't really want to entertain. That and the API wouldn't make
it very pleasant to deal with errors.

I don't know what to make of `useTransition` yet, but I think I'll write another post about it when
I figure it out. This is just a braindump of what I gathered so far.

## Another thought

One thing I've learnt is that you *have* to read from the resource in a different component than
the one you use `Suspense` in, so you can't inline Hello into SuspendTest.

```tsx
const SuspendTest = () => {
  const resource = suspendPromise(async () => {
    await sleep(3000);
    return "from inside a shell";
  });

  return (
    <Suspense fallback="loading...">
      <span>Hello {resource()}</span> // Bad!
    </Suspense>
  );
};
```

And I'm wondering how they will enforce this. Probably just with some error messages and
a slap on the wrist like "the rules of hooks".

---

The full code for this post is available on [CodeSandbox](https://codesandbox.io/s/modest-rosalind-xdpgx).

