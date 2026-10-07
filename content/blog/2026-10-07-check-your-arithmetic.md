+++
title = "Check your arithmetic"
date = 2026-10-07

[taxonomies]
tags = ["rust", "patterns"]
+++

If you have a binary parser that accepts lengths or sizes and you need to do arithmetic on them, you should use checked arithmetic operators!

In this post I'll go over what integer overflow and underflow is, an example of integer overflow going wrong, how to fix it in Rust, and how you could potentially fix it in your next language.

## The overflow bugs in my RAR parser

One of my projects is a RAR decompressor in (pure) Rust. Right now it can only parse unencrypted archive metadata but I figured I'd set up [`cargo fuzz`](https://github.com/rust-fuzz/cargo-fuzz) before moving on.

From what I understand, `cargo fuzz` compiles with the `release` profile but keeps `overflow-checks = true` so integer overflow results in a panic. I set up the fuzzer to generate random bytes for all three RAR metadata parsers. It immediately found some integer overflows!

RAR files are made up of several blocks. Some of them contain metadata, and others contain compressed files. Each block starts with a header that reports the size of the header itself, and of the data contained within the block.

This is a simplified version of what the code that reads a RAR50 header looks like:

```rust
fn read_header<R: std::io::Read>(file: &mut R) -> io::Result<BlockHeader> {
    let header_crc32 = read_u32(file)?;
    let header_size = read_vint(file)?; // read a variable-size integer
    let block_type = read_vint(file)?;
    let flags = read_vint(file)?;

    let extra_area_size = if flags & 0x01 != 0 {
        Some(read_vint(file)?)
    } else {
        None
    };

    let data_size = if flags & 0x02 != 0 {
        Some(read_vint(file)?)
    } else {
        None
    };

    // ...
}
```

Blocks are accessed through a `BlockIterator`, which uses this `header_size`, `extra_area_size`, and `data_size` to figure out the offset in the file of the next block.

```rust
impl<R: std::io::Read> BlockIterator<R> {
    fn read_block(&mut self) -> Result<Block, Error> {
        self.file.seek(io::SeekFrom::Start(self.next_offset))?;

        let block = Block::read(&mut self.file)?;

        let block_size = block.header_size + block.extra_area_size + block.data_size;

        if block_size == 0 || self.next_offset + block_size > self.file_size {
            return Err(Error::CorruptHeader);
        }

        self.next_offset += block_size;

        if let BlockKind::EndArchive(_) = block.kind {
            self.done = true;
        }

        Ok(block)
    }
}
```

The fuzzer took less than a second to panic on an integer overflow on one of the additions in this block. And if you think about it, it's obvious: we're using untrusted input without doing any bounds checking.

## Overflows and nasal demons

Integers generally[^1] have a fixed size and range: a `u8` can only represent values from `0` to `255`, and when an arithmetic operation crosses one of those boundaries, bad things might happen. When we go above `255` it's called integer overflow, and when we go below `0` it's underflow.

In C, integer overflow un unsigned types (such as `u8`) is undefined behavior, which in [popular culture](https://en.wikipedia.org/wiki/Undefined_behavior) is thought to cause demons to fly out of your nose. Until C23, the standard library provided no recourse to this, and I think it's telling that the readme for [this library implementing C23's checked arithmetic](https://github.com/jart/jtckdint) prefaces the "Correctness" section with this sentence (emphasis mine):

> Most everyone who's implemented C23 checked arithmetic has gotten it wrong. Even GNU and Intel have shipped incorrect implementations. We **think** we got it right.

This is clearly a hard problem! If you follow the programming blog aggregators you might have come across a recent back-and-forth[^2] about whether to use signed or unsigned integer types by default, for indices, or at all. Signed integer types (such as `i32`) define overflow to wrap around, so this problem is somewhat diminished, or at least easily sidestepped in the general case by checking whether the result is `< 0`.


## Wrapping safely in Rust

Rust handles integer overflow differently depending on the profile: in `debug` they panic on over/underflow, while on `release` they wrap around.

Thankfully, Rust also gives us tools to handle this. Integer types like [`u8`](https://doc.rust-lang.org/std/primitive.u8.html) expose a few different familes of arithmetic methods for many different situations:

- `checked_*` return `None` when the operation would cause an overflow or underflow.
- `strict_*` panics when the operation would cause an overflow or underflow, even in the `release` profile.
- `wrapping_*` explicitly allow over/underflow, even in the `debug` profile.
- `saturating_*` clamp the operation at the integer's numeric bounds: `255u8.saturating_add(1)` returns `255`.
- `overflowing_*` allow over/underflow and return `(T, bool)`, the latter `bool` indicating whether the over/underflow occurred.
- `carrying_mul`/`carrying_mul_add` return the overflow in the second item of a tuple.
- `unchecked_*` assume that overflow cannot occur and will result in undefined behavior when it does; for this reason, they're marked as `unsafe`.

To fix the overflow in my parsing code, I used `checked_add` and returned an error on overflow:

```rust
let block_size = block.header_size
    .checked_add(block.extra_area_size).ok_or(Error::CorruptHeader)?
    .checked_add(block.data_size).ok_or(Error::CorruptHeader)?;
```

## What do we do about this?

Why did I make this mistake while writing the parsing code?

I guess I just didn't think it through. Integer addition looks like a very natural operation: it's the first we learn about in school and when we sit down to write some code, we expect it to work just like we were taught in school. I expected fixed size integers to work like natural numbers.

The other part is the language's fault, I think. Rust's arithmetic operators hide the overflowing behavior in `release` builds, but the panic on `debug` builds makes me think that this might've been a hot topic at some point during the language's development.

I'm not sure what can be done about this. What would a beginner Rust programmer think if they wrote `let n = 1u8 + 1;` and found that `n` was a `Result<u8, Overflow>`? If `array[2]` returned `Option<T>`?

## Appendix on language design

I'm slowly working on a "systems scripting" language that will use 64-bit integer types by default and I'm kinda tempted to leave arithmetic operators out and just provide functions that will explicitly define their wrapping behavior, so that if you need different wrapping behavior it will not look out of place.

I think this might turn some people away but it's an interesting experiment to consider. In [an episode](https://shows.acast.com/software-unscripted/episodes/gleams-design-and-compiler-with-creator-louis-pilfold) of the podcast "Software Unscripted" Louis Pilfold (creator of [Gleam](https://gleam.run/)) talked with the host Rich Feldman (creator of [Roc](https://www.roc-lang.org/)) about his decision not to include `if` in his language. He said it started as an experiment, and he found that after an initial moment of culture shock, people didn't miss `if` as much as he thought.

Would leaving binary arithmetic operators work just as well? I'm not sure. I happened to listen to a podcast, or a youtube video, where Casey Muratori argued strongly in favor of binary operators. He shared this anecdote: he had recently added operator overloads to a vector type, and while converting the code from function calls to binary operators, he found several bugs. Binary operators made things that much clearer.

I think a better model for arithmetic operators could take inspiration from OCaml. OCaml has two features that I haven't seen in any other language (maybe Haskell has them) and can work in tandem to solve this exact problem.

1. Binary operators are functions like any other:

   ```
   $ nix run nixpkgs#ocaml
   OCaml version 5.4.1
   Enter #help;; for help.

   # ( + );;
   - : int -> int -> int = <fun>
   ```

2. Modules can be "locally opened":

   ```
   # #show_module String;;
   module String :
     sig
       type t = string
       ...
       val concat : string -> string list -> string
       ...
       val starts_with : prefix:string -> string -> bool
       ...

   # String.(concat "-" ["a"; "b"] |> starts_with ~prefix:"a-");;
   - : bool = true

   # let open String in
     concat "-" ["a"; "b"] |> starts_with ~prefix:"a-";;
   - : bool = true
   ```

...so you could define a module defining binary operators that have the wrapping behaviors you want in that case.

```ocaml
module Wrapping = struct
  let ( + ) = wrapping_add
  (* ... *)
end

module Checked = struct
  let ( + ) = checked_add
  (* ... *)
end

let () =
  let _ = Wrapping.(Int.max_int + 1) = -4611686018427387904 in
  let _ = Checked.(Int.max_int + 1) = None in
  ()
```

Then you wouldn't have binary operators in the "prelude" of the language, and you'd have to reach for one of the versions explicitly. How about that?

[^1]: Some scripting languages (like Python and Ruby) have infinite precision integers, so you'll never run into this problem.

[^2]: You'll find links to a few of them along with Odin's language designer gingerbill's take on [this post](https://www.gingerbill.org/article/2026/05/03/signed-by-default/).
