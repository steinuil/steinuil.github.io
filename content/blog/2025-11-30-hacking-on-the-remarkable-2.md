+++
title = "Hacking on the reMarkable 2"
date = 2025-11-30

[taxonomies]
tags = ["remarkable", "reverse-engineering"]
+++

Since last Wednesday, I am the proud owner of a [reMarkable 2](https://remarkable.com/products/remarkable-2). There was a black friday discount and some refurbished deals that meant I could get the tablet, the Marker Plus and the book cover for a little over the asking price of the base tablet and marker so I decided to take advantage of it.

## A short review

The reMarkable is marketed as a distraction-free reading and writing device, and I can confirm that it excels at writing. The friction of the stylus on the epaper display feels just right, the latency is low enough that it resembles writing with ink that takes an instant to set on the page, and you can customize the brush enough to achieve whatever effect you want. I haven't written this much since I was in high school and I think I kind of missed it.

The Marker Plus includes an eraser on the other end of the stylus; if you're thinking of getting one of these things I'd recommend spending a bit more to get this version of the marker because I can imagine erasing things to get very annoying. The other options you have for erasing are a two-tap gesture to undo the last stroke (which I use a lot to delete the last letter if it didn't turn out right), and a selection eraser tool which is useful for deleting entire paragraphs.

The touch gestures are not great: they don't always register and they always need a bit more pressure than you might expect. Navigating with the stylus is much more pleasant, but some things (turning pages) you can only do by swiping. The reMarkable 1 used to have three physical buttons below the screen, and I wish the second iteration had kept those.

Reading PDFs is serviceable (papers are kind of annoying to read because you have to zoom in just a little to read comfortably) and I haven't tested ebooks yet.

Obviously the reMarkable has [its own subscription service](https://support.remarkable.com/s/article/About-Connect-Subscription) called Connect that unlocks some useful features like unlimited cloud storage (the free plan seems to delete files from the cloud after 50 days of inactivity), editing documents in the companion desktop and mobile apps, "premium templates", screen sharing, an extended warranty, and a few other things.

At $29.90 a year honestly it's not such a bad deal, and even the free plan's limitations are not too bad. The signup procedure for my.reMarkable deceptively funnels you into signing up for a 50 day trial and I couldn't find a comprehensive page that shows what you get without paying, but if you don't give up your payment info you'll find that you can still see your cloud synced files and enable the Google Drive/Dropbox/OneDrive integration.

## Reading sheet music

One of the reasons why I wanted to get an epaper tablet was to read sheet music. I sing in a choir and we have a concert coming up during which we won't be allowed to use regular tablets due to the backlighting, and it felt like the perfect excuse to get one of these things to play with.

Reading sheet music is not great on the reMarkable. The refresh rate while turning pages is serviceable, and annotating PDFs with the stylus is a great experience, but there's a few features I have gotten used to on MobileSheets on my tablet that the reMarkable does not support:

- Cropping pages individually. The document viewer lets you zoom in, but it's imprecise and it gets applied to the whole document, and I don't think the zoom level and offset is saved when switching to another document.
- Half-page turning. When you turn a page in MobileSheets, you can set it to overlay half of the next page on the current one so you can follow the last bar while checking what's coming up next.
- Turning pages with a single touch. I mentioned that I don't really like the swipe gestures and I'm not looking forward to fighting gesture recognition while trying to turn a page during a performance.
- Library management. The reMarkable only displays a PDF's filename, but I like to keep my scores indexed by both name and composer/arranger and I'd much rather use metadata rather than a naming scheme to manage them.
- Setlists. During a performance you don't want to be searching for the next piece and most pieces are going to be shared between many concerts. While you can organize documents by folder, duplicating a score in many different folders is not ideal.

These features are non-negotiable for a good music sheet reader and the reMarkable's stock software is not up to par. When I bought the reMarkable 2 I figured I could *just* write my own PDF reader and manager for it and work these features into it.

## Running homebrew software

The reMarkable is a computer like any other, so I believe that since I bought it, I own it, and I should be able to run whatever software I want on it. On this front I have to give credit where it's due. reMarkable the company could've easily locked the device down to get you to pay for its subscription and buy new iterations of the device when they end support for the old ones, but if you go into the **Settings > Help > Copyright and licenses** menu you'll find a paragraph explaining that to comply with the GPLv3 the end user should be able to modify the software that's running on the device, and below that a short explaination on how to SSH into the reMarkable as `root`.

At first glance the reMarkable has an active homebrew software ecosystem too. There's [a community-maintained wiki](https://remarkable.guide/) with guides on [how to install toltec (a package manager)](https://remarkable.guide/guide/software/index.html) and [developing software](https://remarkable.guide/devel/index.html) for the device. After I unpacked the tablet I was eager to get Toltec running and install some software, but...

![Toltec only supports OS builds between 2.6.1.71 and 3.3.2.1666](toltec-versions.png)

Toltec has [strict bounds](https://toltec-dev.org/#install-toltec) on which versions of the reMarkable OS it supports. After unboxing and setting up my reMarkable 2 I ended up on version 3.23.0.64, which is way beyond what Toltec supports. Am I cooked? Well, the guide mentions that you *can* [downgrade to a different OS version](https://remarkable.guide/faqs.html#can-i-downgrade-to-a-different-os-version), so maybe...

> ### [Caveat for downgrading from 3.11.2.5 or greater to a version less than 3.11.2.5](https://github.com/Jayy001/codexctl?tab=readme-ov-file#caveat-for-downgrading-from-31125-or-greater-to-a-version-less-than-31125)
> If your reMarkable device is at or above 3.11.2.5 and you want to downgrade to a version below 3.11.2.5, codexctl cannot do this currently. Please refer to [#95 (comment)](https://github.com/Jayy001/codexctl/issues/95#issuecomment-2305529048) for manual instructions.

Ok, looks like you can do it, but if you want to downgrade that far you're looking for trouble. But why do I have to do this, have the maintainers simply lost interest? Let's take a look at [the GitHub issue](https://github.com/toltec-dev/toltec/issues/859) that tracks newer OS builds support.

![Due to the current state of rm2fb support in the community. We will not be supporting every OS release after 3.3.2. Instead, we will be adding 3.5.2 and 3.8.2 support. When timower's rm2fb is updated to support newer OS versions, we will work on only supporting those versions.](rm2fb-support.png)

Ah. And what exactly is [rm2fb](https://github.com/ddvk/remarkable2-framebuffer) then?

![rm2fb can open the framebuffer and draw to it. rm2fb-server exposes a simple API for other processes to draw to the framebuffer using shared mem and message queues. rm2fb-client is a shim that creates a fake framebuffer device for apps to use, allowing rM1 apps to seamlessly draw to the display of the rM2.](rm2fb-readme.png)

Ok. I don't understand why you'd need to use shared memory and message queues to draw to a framebuffer, but maybe the rest of the README will have more clues on that. If you scroll down to the FAQ there's a helpful link called [how does rm2fb work?](https://github.com/ddvk/remarkable2-framebuffer/issues/5#issuecomment-718948222)

> The server process will rely on using functions from either `xochitl` or `remarkable-shutdown` but those processes don't actually run. We use LD_PRELOAD to take over the process, like `LD_PRELOAD=rm2fb.so xochitl` and then we use our own main() func but call into the APIs we need to 1) start the SWTCON threads and 2) send updates. If we go server model, this only needs to happen once (instead of each application doing this dance)

At this point we should talk about `xochitl`.

## Proprietary software woes

`xochitl` is [the main application running on the reMarkable](https://developer.remarkable.com/documentation/xochitl), and it is proprietary software. Unfortunately it also makes for the only documentation the homebrew community has for driving the framebuffer that draws to the reMarkable's epaper display; the [SDK](https://developer.remarkable.com/documentation/sdk) provided by reMarkable only supports [Qt Quick](https://developer.remarkable.com/documentation/qt_epaper) so if you don't want to use Qt or link to `libqsgepaper.so` you're stuck with reverse engineering `xochitl`.

The reMarkable 1's display driver seems to have been completely reverse engineered, but not the reMarkable 2's (except for individual efforts, which I'll talk about later).
Most of the homebrew programs for the reMarkable are written to directly draw to the framebuffer, and they expect to interact with the reMarkable 1's framebuffer.

`rm2fb` comes in as a compatibility layer that allows programs that interact with the rm1's framebuffer to run on the rm2. Since the rm2's framebuffer driver had not been completely reverse engineered when this was developed, `rm2fb` hooks into `xochitl` and uses its code to interact with the framebuffer. This relies on `rm2fb` knowing the offsets and the signatures of those functions into the `xochitl` binary, so obviously when the OS build changes and `xochitl` is upgraded, those offsets and signatures are invalidated and `rm2fb` will stop working until somebody works those out again.

## Freeing the reMarkable 2 from Xochitl

At this point I had already loaded up `xochitl` into Ghidra and I was starting to figure out how the framebuffer is used inside it. I mean, how hard could it be?

![`xochitl` in Ghidra with the `ioctl` function highlighted](xochitl-in-ghidra.png)

I mostly searched for calls to `ioctl` and quickly made some good progress. Then I figured that if this was so easy somebody else with more experience than me must have have already done it, so I did some more searching.

`rm2fb`'s FAQ section also includes another link, [what about implementing an open source SWTCON?](https://github.com/timower/rM2-stuff/) which links to a repository containing [a version](https://github.com/timower/rM2-stuff/?tab=readme-ov-file#rm2fb) of `rm2fb` that works on newer OS build versions, and [an initial implementation](https://github.com/timower/rM2-stuff/?tab=readme-ov-file#swtcon) of a reMarkable 2 display driver that only relies on `xochitl` for some things. I also joined the reMarkable community Discord server to see if I could glean more info. There were some posts by [timower](https://github.com/timower) (the owner of the `rm2-stuff` repo) talking about the problems they faced while reverse engineering it.

![Screenshot of the Discord server with comments by timower and okeh explaining the generator thread](discord-generator-thread.png)

A few years later, [Mattéo Delabre](https://github.com/matteodelabre) shared a link to [a repository](https://github.com/matteodelabre/waved) containing a C++ driver for the reMarkable 2 display that did not rely on on `xochitl`, though development seems to have stagnated around 2022. Then a few months ago, [jakubvf](https://github.com/jakubvf) shared [their own implementation](https://github.com/jakubvf/dazed) of a rm2 display driver in Zig with support for SDL3.

Neither of these efforts seem to have caught on, but the Toltec maintainers are working on support for newer OS build versions that can safely be downgraded to from 3.23.\* so I hope that in the near future I'll be able to install Toltec on my device without messing too much with it.

As for me, I started my yak shaving chain to build the music sheet reader by [reimplementing waved/dazed](https://github.com/steinuil/remfab) in my poison of choice, Rust. I'm not going to finish this program in time for the concert but that's ok.

This is where I would've liked to include a section on how you can drive the reMarkable 2's display with just a few syscalls but I'm still figuring that out! This post has already turned out to be longer than I thought so I'll leave that stuff for a possible future post on how to write software for the reMarkable 2.

Lastly, I'd like to thank the reMarkable hacking community for all their work on reverse engineering and developing software for it, because I would definitely have regretted this purchase if it weren't for their efforts.

![Thanks for reading!](thanks-for-reading.jpg)
