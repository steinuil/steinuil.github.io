## Moving out

This morning as I was having breakfast I read a blog post called
[Why not GitHub?](https://sanctum.geek.nz/why-not-github.html), in which the writer
argues against the centralization of all open source activity on GitHub.

Variations on this post are constantly being spammed on all major link aggregators
for the last few years. I find myself re-reading it at least once a week.
Sometimes it's about [personal websites](https://www.vanschneider.com/a-love-letter-to-personal-websites),
sometimes about [mail providers](https://poolp.org/posts/2019-08-30/you-should-not-run-your-mail-server-because-mail-is-hard/),
but the core message is more or less the same: $bigcorp is evil and wants to
make everybody use the same 5 websites, so that when they start pushing their
bullshit onto us there'll be nobody left to complain.

I think the spam is working, because I've been thinking about these things a
lot lately.

---

This is the part of the post where I provide a righteous moral justification for
getting off every centralized service and embracing the open web and self-host
everything. Ready?

I don't have one. If you're looking for a great argument in favor of all these
nice things there's lots of other people who can talk to you at length about them.
I just like to hack on things, and if those things are on Google's servers then
I can't hack on them.

There's a kind of warm and fuzzy comfort in letting these big corporations
manage these things for you. They do their best to keep you happy and well-nourished.
The world out there is cold and unforgiving.
And they probably already have more info on you than you could ever have, so what's a
couple more droplets in the ocean?
I wouldn't know how to blame you for never moving out.

![You are safe now, my sweet child](/assets/images/you_are_safe.jpg)

That said, I've been wanting to do it for a while now, and since this makes for
good blog content these days I'll be documenting my process in a series of posts,
from deciding on a hosting platform to all the intricacies of setting stuff up.
There's a couple things I want to self-host:

- email
- git frontend
- this website
- IRC bouncer
- simple file hosting
- mastodon-compatible thing for me and a couple friends maybe

I'll do it in NixOS because that's how I roll lately, so hopefully I'll end up
with a nice `configuration.nix` that you can steal snippets from. It might take
a while, but I'm committed to it.