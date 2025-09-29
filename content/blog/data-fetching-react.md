+++
title = "A data-fetching component in React"
date = 2019-05-10
+++

Remember last year's [talk][suspense-talk] about Suspense by Dan Abramov?
I was still mostly learning React when that was uploaded to youtube, and
seeing him talk about just this issue and presenting this magic API that
seemed to solve it without much effort got me really hooked.
But then [Suspense][suspense-doc] actually comes out and (even an year
later) it's just about code splitting. What gives?

Fast forward one year, I was refactoring parts of a smallish React app and
taking the opportunity to learn hooks, and I noticed I had a lot of components
that shared roughly this structure (plus some unrelated UI state sprinkled in
for good measure):

```tsx
class CookieCutter extends React.Component {
  state = {
    hasLoaded: false,
    data: null,
  };

  componentDidMount() {
    this.props.fetchData().then((data) => {
      this.setState({
        hasLoaded: true,
        data,
      });
    });
  }

  render() {
    const { hasLoaded, data } = this.state;

    return hasLoaded ? (
      <div>{data}</div>
    ) : (
      <div>Loading...</div>
    );
  }
}
```

And since I had just spent all day decomposing old monstrous class components
and otherwise wasting time polishing parts of the app like an art project,
I started thinking about how I could extract this pattern so it would look like
the vague memory I had of Suspense. For reference, this (part of) Suspense's
API:

```tsx
<Suspense fallback={<div>Loading...</div>}>
  <NewComfort />
</Suspense>
```

Something kind of bothers me about this API: where's the data? How does
`Suspense` know that whatever data `NewComfort` needs has finished loading?
It looks like the data flows downwards from `NewComfort`, but also upwards
towards `Suspense`? I guess I'm just not used to this stuff, but I thought
it'd be better to be a bit more explicit, even if it increased verbosity.
I'm also not a huge fan of higher-order components, so instead I decided to
rely on the good old trick of [render props][render-props].

```tsx
<LazyLoaded
  provider={fetchData}
  fallback={<div>Loading...</div>}
>
  {(data) => (
    <ChocolateMatter data={data} />
  )}
</LazyLoaded>
```

`LazyLoaded` is probably not a very good name, but I decided to go with that.
I was still on the hooks hype train so I went out of my way to implement it
using hooks:

```tsx
interface Props<T> {
  provider: () => Promise<T>;
  fallback?: JSX.Element;
  children: (data: T) => JSX.Element | null;
}

export function LazyLoaded<T>({
  provider,
  fallback,
  children
}: Props<T>) {
  const [data, setData] = React.useState<T | null>(null);

  React.useLayoutEffect(() => {
    setData(null);
    provider().then((data) => {
      setData(data);
    });
  }, [provider]);

  return data ? children(data) : fallback || null;
}
```

And this worked well enough. At first I implemented it using `useEffect`, but I
noticed that `useLayoutEffect` would actually skip the split-second load that
occurred when the `provider` resolved immediately if the data was already in
the cache.

But there's a big issue with this implementation. Do you see it? I didn't until
I actually tested the component on the real page. Consider this:

```tsx
type Page = 'VELOCITY' | 'DESIGN' | 'COMFORT';

const Main = ({ cache }) => {
  const [page, setPage] = React.useState<Page>('VELOCITY');

  return (
    <div>
      {page === 'VELOCITY' ? (
        <LazyLoaded
          provider={cache.getTekka}
          fallback={<div>Loading tekka...</div>}
        >
          {(data) => (
            <Velocity data={data} setPage={setPage} />
          )}
        </LazyLoaded>
      ) : page === 'DESIGN' ? (
        <LazyLoaded
          provider={cache.getDsco}
          fallback={<div>Loading dsco...</div>}
        >
          {(data) => (
            <Design data={data} setPage={setPage} />
          )}
        </LazyLoaded>
      ) : (
        <Comfort setPage={setPage} />
      )}
    </div>
  );
};
```

We land on`'VELOCITY'` and switch to '`COMFORT'` and then to `'DESIGN'` and
everything is good. But then from `'DESIGN'` we switch the page back to
`'VELOCITY'` and everything breaks. What just happened?

To understand this, you should know a bit about what React calls
[reconciliation][reconciliation]. To ensure that the whole page isn't
unmounted and remounted every time something changes, React will look at the
component tree and do some diffing to make sure that only what actually needs
to be updated will be.

In particular, React will look at the "type" of component, and if it remains
the same between two updates it will avoid unmounting and remounting it. In
this case this is pretty bad news, because when we switch between the two
pages above that have a LazyLoaded component at the same level of the render
tree, `LazyLoaded` will not *not* get unmounted. In the first paint we end up
with an invalid state in which the `children` function is the new one from
`'VELOCITY'`, but the `data` is the old one we fetched in `'DESIGN'`.

So how do we fix it? The first and dumbest thing that came into mind was make
sure that `LazyLoaded` is unmounted whenever we change the page. React
provides a default prop on all components that just about does this this
called `key`.

```tsx
page === 'VELOCITY' ? (
  <LazyLoaded
    key="VELOCITY"
    provider={cache.getTekka}
    fallback={<div>Loading tekka...</div>}
  >
    {(data) => (
      <Velocity data={data} setPage={setPage} />
    )}
  </LazyLoaded>
) : page === 'DESIGN' ? (
  <LazyLoaded
    key="DESIGN"
    provider={cache.getDsco}
    fallback={<div>Loading dsco...</div>}
  >
    {(data) => (
      <Design data={data} setPage={setPage} />
    )}
  </LazyLoaded>
) : (
  <Comfort setPage={setPage} />
)
```

By making `key` required in `LazyLoaded`'s prop type and adding a threatening
doc comment I more or less ensured that users of this component would always
add a "reasonably unique" `key` for the part of the render tree `LazyLoaded`
would be used in. And this worked well and things were good.

It's kind of a hack though, so the other day I came back to this component and
deleted both the key from the prop type and the threatening comment.
Considering the relationship between all the bits that form the state of the
component, it becomes obvious that a certain `data` can only be associated
with the `children` function from the render from which we also got the data's
`provider`. With that in mind, we should modify the component a bit:

```tsx
interface State<T> {
  data: T;
  childrenSync: (data: T) => JSX.Element | null;
}

export function LazyLoaded<T>({
  provider,
  fallback,
  children
}: Props<T>) {
  const [state, setState] =
    React.useState<State<T> | null>(null);

  React.useLayoutEffect(() => {
    setState(null);
    provider().then((data) => {
      setState({
        data,
        childrenSync: children,
      });
    });
  }, [provider]);

  return state
    ? state.childrenSync(state.data)
    : fallback || <Loading />;
}
```

Remember that, being a closure, the useLayoutEffect callback will capture the
value of `children` at the time it is defined, so since we defined our types
correctly we can be sure that the value returned from the `provider` will
always match the one expected from the `children`.

And now everything is good again. (The error handling and cancellation in this
component are left as an exercise to the reader.)

I really like this pattern, but I haven't found anything similar to it online
when I searched. Maybe I'm just looking in the wrong places? Or maybe other
people that came up with this thought it was too simple to warrant writing
about it? Nevertheless, I thought it was worth sharing because it's nice and
presented a problem with a non-obvious solution, unless you're familiar with
some of React's internal workings. Maybe somebody will get a kick out of this.

[suspense-talk]: https://www.youtube.com/watch?v=6g3g0Q_XVb4
[suspense-doc]: https://reactjs.org/docs/code-splitting.html#suspense
[render-props]: https://reactjs.org/docs/render-props.html
[reconciliation]: https://reactjs.org/docs/reconciliation.html
