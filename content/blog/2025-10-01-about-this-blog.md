+++
title = "About this blog"
date = 2025-10-01

[taxonomies]
tags = ["zola"]
+++

I just changed my blog's tech stack, so the time has come for me to write the obligatory meta-post about my blog.

I spent thursday night setting up this blog again, throwing out my own [Racket](https://racket-lang.org/)-based [static blog generator](https://github.com/steinuil/steinuil.github.io/blob/master/generate.rkt) and replacing it with [Zola](https://www.getzola.org/). I'm not particularly happy about killing my generator, but it was either choosing an off-the-shelf option or reimplementing a parser for a Markdown-based Racket `#lang` that let me escape to Racket in a similar way to [Pollen](https://docs.racket-lang.org/pollen/index.html) and rewriting my (admittedly not very long tail of) previous posts in this new language, and I wasn't making much progress on that front.

Why throw out the old stack? Well, I had a few annoyances about how it worked. First of all, the [Markdown library](https://docs.racket-lang.org/markdown/index.html) I was using did not handle Markdown extensions like tables, and there wasn't a way I could plug into the parser to implement those or add custom elements such as _Cool Bear's hot tips_ from [@fasterthanlime's blog](https://fasterthanli.me/).

Then there was the problem of footnotes: the library generates unstable IDs for footnotes, so every time I regenerated the blog every single ID would change, which was annoying and led me to this cycle of generating the blog, then manually `git restore`ing every page that was not supposed to be touched by the change. It was all a bit laborious. I'd also like to implement footnotes in the sidebar, and again, the library made it all kind of tedious.

These were not insurmountable problems. I could probably embed the library into the generator and hook into the [SXML](https://docs.racket-lang.org/sxml-intro/index.html) emitter to change the output it produces. I just never felt like doing that. Maybe I just don't like working in Racket anymore because it's generally untyped and its [typed variant](https://docs.racket-lang.org/ts-guide/) is excruciatingly slow and often very annoying to work with.

It took me a few hours of work to get Zola running and redesign the blog. I wrote a custom template, changed all the fonts, finally added support for [tags](/tags/), made sure that all the old posts would render correctly, and aliased all the old URLs to the new ones. Zola has a built-in server with live reload that made this process much quicker. It was all very easy.

I went with Zola entirely based on vibes, but I think I like its approach. It tries to generalize some standard things you'd want in a blog into more powerful concepts: posts become a [section with pages](https://www.getzola.org/documentation/templates/pages-sections/), tags become one of many [taxonomies](https://www.getzola.org/documentation/templates/taxonomies/) that the website can have. Just about every template is customizable. It looks very fast: my whole blog renders in a hundred milliseconds, which sounds about right. I also set up its premade GitHub Actions workflow for deploying the blog to GitHub pages.

I can't say I _enjoy_ writing [Tera](https://keats.github.io/tera) templates and this was one of the issues that made me procrastinate the switch to an off-the-shelf generator, but honestly, they're fine. The one thing I dislike is that they're orthogonal to the text they produce, so a few times during the template writing process I ended up with invalid HTML. I'm not happy about that, but sometimes you just have to compromise.

I took some inspiration from [Devine Lu Linvega's website](https://wiki.xxiivv.com/site/home.html) for the top bar. You can find the fonts that I used on the [meta](/meta/) page: I think they look nice.

There are some things that I'd like to implement in the future:

- Footnotes in the sidebar, as I previously mentioned.
- Comments? I wouldn't want to use a third-party thing, especially not after I read that [Disqus injects tons of ads into your page](https://ryansouthgate.com/goodbye-disqus/), so maybe I'll hack some custom solution together.
- I had this idea that I could publish this blog as an [AT proto](https://anil.recoil.org/notes/atproto-for-fun-and-blogging) thing just because I think it would be cool, but that probably involves changing the whole stack again. Something to think about for the future.

In conclusion, hats off to Zola for making the migration process very painless, and I hope this improved process will make me more likely to write posts on here.
