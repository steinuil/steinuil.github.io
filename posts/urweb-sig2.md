It's been a while since the last post, so I'd say a review of the stuff we
covered in the last part is in order. This is `List.mapM`:

```urs
val mapM :
  m ::: (Type -> Type) -> monad m
  -> a ::: Type -> b ::: Type
  -> (a -> m b) -> list a -> m (list b)
```

`List.mapM` maps a function returning a monad over a list.
`m ::: (Type -> Type)` is the type of a type-level function,
or a constructor, like for example `option`. `monad m`
constrains `m` to a type for which there exists in scope
an implementation of the `monad` typeclass. `a` and `b` are the
polymorphic type parameters, and `(a -> m b) -> list a -> m (list b)`
is simply the type of the function.

# Names and Records

While normal types are of kind `Type`, record field names are a
