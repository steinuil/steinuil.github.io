I'm sure you know what bikeshedding means, and even if you don't, you've probably
experienced a high amount of it in some way or another. It's a folkloristic[^1]
programming term that describes the endless discussion over trivial aspects of a
piece of software, such as spaces vs tabs, or which of the zillions of JS build
systems to use, or whether operator overloading should be allowed. We'll call these
*social issues*.

The great thing about social issues is that they only exist when more than one person
is working on a project. If it's just you, you don't have to worry about coding
style guidelines. You don't have to worry about what paradigm you want to use, or
to get everybody comfortable with the set of macros you're using, or with the libraries,
or the build system. In fact, you won't have to worry about reproducing the build
environment on machines other than your own. You might even get away with not documenting
your code, even though your future self will hate you for that.

Rudolf Winestock in his famous article
[The Lisp Curse](http://winestockwebdesign.com/Essays/Lisp_Curse.html) argues that
*"Lisp is so powerful that problems which are technical issues in other programming
languages are social issues in Lisp."* This makes Lisp a great language for lone
hackers, because those social issues are easily solved by oneself, but terrible
for working with other people, because you'll have to spend so much time just defining
a common language that everybody agrees to use that you'll never see the end of it.

This is a problem in C++, too: the joke goes that the language is so big and full
of features that you'll end up using only 10% of it for any given task, but everybody
disagrees on what that 10% should be.

## Enter Go

Go is a pretty [unremarkable](https://youtu.be/_1GZShA1F20?t=42m13s) programming
language, with a feature set that [rivals](https://cowlark.com/2009-11-15-go/) that
of languages from the 60s, and it's also one of the most popular programming languages
of the last few years. I think the reason is that whatever thought didn't go into
making a good programming language went into solving the social issues that the
other languages suffer from, and if you ask people who have experience with many
languages what they like about Go they'll mostly praise what you could call its
"user experience".

Go tries to solve the social issues by providing solutions for them by default in
its standard installation, down to including a code formatter that the vast majority
of projects require you to run before committing any code to source control.

Go also makes lots of tradeoffs in the language itself to make compilation faster:
the type system is very limited and you don't get type inference other than some
syntactic sugar for C++'s `auto` keyword, because the compiler would have to perform
more extensive type checking. Generics also don't exist, because you'd have to generate
code for each instantiation at compile time.

I personally don't agree that these tradeoffs are really worth it, but it seems
to be working. People love Go (i.e. its tooling), and they love how they don't have
to think about all the things Go provides anymore, which I think raises a good point:
isn't not worrying about the unimportant parts what programming languages are about?
And if so, **what good is a new language that doesn't try to solve these issues?**

## Lessons to be learned

I think that there's lots of better languages out there that should learn a thing
or two from Go, if they want to succeed.

Elm seems to be a step in the right direction: it takes a lot from Haskell, and
makes a lot of decisions and tradeoffs to be easier to learn for newcomers. Elm
places a tremendous amount of effort into appealing to newcomers by having a very
small core language, integrating many tools into its standard distribution like
Go, and making error messages look very friendly and easy to understand.

Then again, many of these improvements are implemented without regard for the more
experienced developers. Elm is a great language and its architecture is a really
good paradigm, but many complain that it scales poorly when project sizes increase,
and without stronger abstraction facilities like type classes you're bound to end
up with a lot of boilerplate. Frankly, I don't think Evan himself knows where he
wants to bring the language in the future.

[Reason](https://reasonml.github.io/) also seems to be somewhat promising, being
funded by Facebook and all. It's nothing but a layer of paint on top of OCaml to
make it look more like Javascript, but somehow it's managed to make people buy into
it. The Reason team also seems to be working on the OCaml compiler to make it produce
error messages that look like Elm's. With a bit of luck, this will bring more people
over to OCaml and, over time, improve its ecosystem.

[^1]: I've stolen this use of the term from [this talk](https://www.youtube.com/watch?v=4PaWFYm0kEw) by Bryan Cantrill. It's a good talk.
