A few months ago, [Gary Bernhardt](https://destroyallsoftware.com) streamed himself
writing a text editor. I'm not sure he ever finished it, and for some reason he took down
the VoDs on Twitch, but the little I've seen was still very interesting.

Writing my own text editor (and using it) has always been one of my dreams and, being a
vim user, I'd much rather have it run on my terminal. Bernhardt shares my opinion, so he
started by writing (or rather, copying from one of his previous projects) the terminal
interaction code. I've always thought terminal interaction would be pretty complicated,
but it turned out to be a very small amount of code.

This got me wondering about the protocol.

# A brief, incomplete, and mostly wrong history of the TTY protocol

The TTY protocol predates computers by quite a bit, and hasn't changed much since the
late 19th century. The protocol was created for **teletypewriters**, or teletypes,
to communicate with each other: it included not only printable characters such as
numbers, alphabets, and punctuation, but also directives for the teletype that were
not supposed to be printed called **control characters**, such as Line Feed (`\n`).

The character encodings that we still have to deal with nowadays also largely
come from back then: Unicode later tried to patch them all together, but it was already too late.

Then computers came along. Printing the result of a computation to a sheet of paper
was way easier than interpreting a bunch of lights on a front panel, so they stuck
teletypes to them, and thus computers learnt the TTY protocol too.

When screens became widespread, the protocol acquired more commands known as
**escape sequences**, so called because they were prefixed by
ESC (`0x1B`). These allowed computers to move the cursor arbitrarily on the screen,
clearing part of it or applying some effects such as inverting the background and
the foreground color.

Some terminals, such as the Tektronix 4010 series, also allowed drawing lines on
the screen thanks to their vector displays. These unfortunately died an untimely
death (even though a tek emulation mode still lives on inside xterm), and only the
text-based VTs stuck.

# Summing up

For most intents and purposes, `/dev/tty` still behaves a lot like a physical
typewriter: you can scroll the "sheet of paper", you can move the cursor
around, you can imbue its head with colored ink or special effects. You can easily
find your way around with [a control sequences chart](http://www.xfree86.org/4.5.0/ctlseqs.html),
and it's not hard to emulate ncurses or readline just by printing a few characters
in [raw mode](https://en.wikipedia.org/wiki/Cooked_mode).

The TTY is unfortunately very stateful, but [termbox](https://github.com/nsf/termbox)
provides a very nice abstraction: it essentially turns all interactions stateless by printing a few more escape sequences every time you write something.

I'm not sure if I'll ever write my own text editor, but it's certainly fun to play
with terminal graphics and line editing using nothing but `write`.

# Further reading

[Gary Bernhardt - A Whole New World](https://www.destroyallsoftware.com/talks/a-whole-new-world)

[Four Column ASCII](https://garbagecollected.org/2017/01/31/four-column-ascii/)

[The TTY demystified](http://www.linusakesson.net/programming/tty/)

[Declarative terminal graphics for OCaml](https://github.com/pqwy/notty)

[Playing with Tektronix emulation for vector graphics!](http://use.perl.org/use.perl.org/_scrottie/journal/39195.html)

[notty: A new kind of terminal](https://github.com/withoutboats/notty)

[Daniel Morsing - UTF-8](http://systemswe.love/videos/utf-8)

[How Unix erases things when you type a backspace while entering text](https://utcc.utoronto.ca/~cks/space/blog/unix/HowUnixBackspaces)

[When monospace fonts aren't: The Unicode character width nightmare](http://denisbider.blogspot.com/2015/09/when-monospace-fonts-arent-unicode.html)

