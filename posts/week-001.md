Welcome to the first installation of **What The Hell Did I Do This Week Anyway**,
the low-effort blog series where I write about random stuff that I did in the
last few days.

## Emacs strikes again, or the stages of software grief

This week I watched a bunch of Jonathan Blow's [screencasts](https://www.youtube.com/user/jblow888/videos),
where he talks about the language he's writing and all that business. It looks
nice. Lately he's working on libraries, and I wish he'd take a hint from ML
functors when designing modules and module options, as he's talked about in
the libraries discussion stream. Expose a fucking module for configuration and
make it return the full thing, using strings for that just feels painful.

Anyway, he uses emacs for all the programming in his stream, save for debugging
a bunch of stuff in C++, and looking at emacs for all this time has reawakened
the little bug in my brain that tells me to start using emacs already. I use
nvim for everything, but I'm kind of horrified by the whole vimscript business
and at the very least elisp is a saner language.  
Screw learning all those keybinds though. I've spent years on vim and I think
the modal editing business is a much better fit to editing code than the big
mess of emacs keybinds.
Screw using evil too, though, because emacs is not vi and I don't think it
should be. Screw all the minor modes that kind of mimic vi but also kind of
don't, and screw a lot of the packages that emacs comes preloaded with.

I downloaded the emacs source and managed to compile temacs, which is the
"bare" version of emacs that gets filled in with all the preloaded libraries
and elisp code, and then gets "dumped" to the final emacs executable we all
know and fear. I recommend [this](http://emacshorrors.com/posts/unexecute.html)
for the gory details on this horrifying process.
I think there might be a few steps in the build process that should happen
after building temacs but before actually loading temacs and dumping it to
emacs, because I can't get the damn thing to work. I invoke temacs and tell it
to load `loadup.el` (the file that loads all the plugins and tells emacs to
dump itself) but it keeps failing with some error message or another.
First it's pcase, then it's require, and who knows what the next will be.
Despite its reputation for being so hackable, this part of the build process
sure is not, and if it is it's *very* undocumented.

I started writing my own loadup file in hopes of getting it right, but I ran
into some files that supposedly provide Common Lisp support which for some
reason `require` each other. At this point I gave up, because I was already way
past the treshold of time and effort I wanted to allocate to emacs that evening.
Thanks, jwz.

The next step in the stages of software grief is starting to implement your own
version, because you're **so** done with whatever you were using before and its
alternatives and how hard could it possibly be anyway. Which is exactly what I
did, as soon as I remembered that Racket came with a perfectly good library for
drawing stuff on the screen, on top of which they implemented a GUI library and
the very nice editor/IDE DrRacket.
I looked up how Racket implements the editor window, and the results weren't
exactly what I'd call readable or encouragings, after messing a bit with the
`canvas%` class I decided to give up for the moment.

Which is where I reached the last stage of software grief, in which I changed
my vim colorscheme to [deus](https://github.com/ajmwagar/vim-deus) and called
it a day.

## Eight whole bytes of security

I was working on my Ur/Web imageboard, when I noticed that I accidentally typed
"passwords" instead of "password" and still managed to log in. I looked up the
implementation of `crypt` (the only password hashing function provided in
Ur/Web) in the runtime library and discovered that it uses OpenSSL's
`DES_crypt`, which clips passwords to 8 characters (!) and has been deemed
obsolete for decades now (with good reason). I don't know what the
production-class Ur/Web applications do for password hashing, but thankfully
searching for `crypt` in both the Bazqux Reader and UPO repos doesn't turn
up any results. Either way, nobody had bothered to write Ur/Web bindings to a
better password hashing algorithm, so I figured I'd do it.

The result is [this library](https://github.com/steinuil/urweb-bcrypt), which
uses Solar Designer's implementation of the algorithm. It only exposes two
functions, so integrating it with my imageboard only took something like two
minutes. I'm quite satisfied with it, though it could probably use some tests.

The other result is that I've submitted a PR with a comment on the `crypt`
function in the Ur/Web standard library, essentially explaining that it's
insecure and you should probably consider an alternative (such as my library).
