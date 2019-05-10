A [recent post](http://250bpm.com/blog:153) on Martin Sústrik's blog about an
alternative shell that stores its state on the filesystem seems to have drudged
up a bunch of other crazy shell ideas that people have conjured and
implemented over the years. Over the past week I've already seen
[dgsh](https://www.spinellis.gr/sw/dgsh/) and
[es](https://wryun.github.io/es-shell/paper.html)
hit the front page on Lobsters; strangely I have yet to see anybody bring up
[Scsh](https://scsh.net/) or make the argument that actually PowerShell ain't
that bad all things considered. I could probably farm a fair amount of upboats
with either of those things, but I trust they will come up eventually on their
own.

This turmoil has also drudged up a bunch of old ideas I've had about shells
and, more specifically, about an imaginary shell which we'll call *Skle*
that have been haunting me for a few years. I'm just gonna dump my thoughts
on here in hopes that it will bring me some kind of catharsis, or lacking
that, that it will provide me with a solid enough roadmap to start working
on this dumb idea.

First of all I'd like to remind everyone that the shell is just a
programming language, usually a particularly bad one geared towards
interactive use and providing a sort of IPC between "functions"
written in other languages. Most shells use internal commands only for those
functions that cannot be reasonably implemented externally, such as "cd", and
search the command path for external commands otherwise.

WIth that in mind, let's go

Skle is first and foremost a programming language. I'm gonna take the (hopefully
not too controversial) stance that a good shell language can only result from a
good(tm) programming language, and that means it's gonna have lexically scoped
variables, named and anonymous functions, immutable data structures, and most
importantly, *static types*.

Yes, types. The shell has classically been stringly typed, making no attempt to
parse the data it handles and instead trusting its functions and commands to
correctly interpret the gibberish it hands them. Supposedly this is one of its
features, because it means that any external commands can accept data from any
other command. Concretely this means that commands are allowed to output
structured data in whatever bullshit semi-structured manner they see fit. Often
this might just happen to be what you need, but sometimes it's not and boy I
sure hope you know your awk and tr. Why is dealing with paths that have spaces
an issue? Why can't we have files that start with a dash, and why is supporting
`--` not a requirement? Does -v mean verbose or version?

PowerShell deals with objects rather than strings, and while that might
cause some problems with encoding thanks to Windows being Windows, I think it's
mostly a huge win. So yeah, Skle is definitely very similar to PowerShell in
that regard. Commands implemented in Skle deal in streams and 




Paths are a separate type from strings, which means that we can't accidentally
mix them up, and that we can check them statically.
Through this and a clever use of functional abstractions
([selective functors](https://blogs.ncl.ac.uk/andreymokhov/selective/) look like
a good fit) we can statically analyze any Skle program and output a list of
files and directories that would be touched in some way or another, or check
that all files and directories required to run a script effectively exist, have
the right permissions set, and that we don't accidentally overwrite anything we
care about, without running anything! Essentially we get --dry-run for
free, which means you can easily review the shady install script you just curled
and piped into eval to see if it does any damage before running it.

Tracking the files required to run a script and the outputs looks suspiciously
like a build system, so selective functors which is the solution adopted by
Jane Street's Dune build system for OCaml sounds like a good idea.



The static types would also help with the interactive bits. Providing correct
completions for any command becomes trivial. Flags would be statically typed too.
Since paths are a different data type from strings we can provide a file browser
whenever we need a path.
paths and strings and other data types would have different quotes but you wouldn't
have to worry about that at the prompt because they would be inserted automatically.

