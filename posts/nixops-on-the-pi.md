TL;DR: if you have an underpowered machine or two in your house or a small server that you're already managing using NixOS, and you find that running `nixos-rebuild` on it takes too long, you can easily keep your current configuration untouched and let a more beefy machine build it. Jump to the end of this post for a sample NixOps specification and instructions on how to use it.

Also, NixOps apparently has some [issues](https://news.ycombinator.com/item?id=20324608) involving local state that make it hard to share a deployment with other machines. I just read about a tool called [morph](https://github.com/DBCDK/morph) that is almost a drop-in replacement for NixOps and doesn't share these issues. Sadly it is 3AM here and this here setup works well enough for me so I really can't be bothered to check it out right now, but maybe at some point I will and maybe you might want to do it upfront. [This](https://christine.website/blog/morph-setup-2021-04-25) is a good post about it.

---

I have a Raspberry Pi 3B+ sitting next to my router. I use it to host a couple things to my local network. You might remember it from [a previous post](https://sgt.hootr.club/molten-matter/nix-distributed-builds/), in which I talked about my experience with NixOS' distributed builds.

It's a relatively slow machine and you really don't want to build things directly on it, so at the time I reached for distributed builds to make the experience of rebuilding my configuration a little less painful. That worked out alright, but we can do better.

While distributed builds *do* make executing a `nixos-rebuild` much faster, the Nix expression describing the whole system is still evaluated on the Pi itself, which in the best case results in a virtually nonfunctional system for a couple minutes, and in the worst a slow death as swap fills out. I usually pull the plug when that happens because I can't stand watching the poor thing suffer like that.

But! There is a fourth solution to this issue that I failed to consider on the previous post though: NixOps! The [NixOps user manual](https://releases.nixos.org/nixops/latest/manual/manual.html#chap-introduction) describes it as:

> [...] a tool for deploying NixOS machines in a network or cloud.

This description initially put me off from using it. It makes it sound like something you'd only use when you have a bunch of servers, and that just using it for managing one machine would be overkill. It also makes it sound like there's a big learning curve, I mean there's a big one page html manual about it and ain't nobody got the time to read *all that*. Figuring out Nix already took me long enough.

And surely I couldn't just `import` the configuration I was using for the Pi and expect it to work with NixOps, right? I'd seen a couple posts about NixOps but they usually involved creating a new server with a new configuration that I didn't really care about, so maybe I'd have to make some changes.

...Or *would I?*

This might be a gross oversimplification, but all NixOps does is evaluate a system configuration on your machine, build it, copy the results on one or more target machines and make them switch to that configuration.

In other words, it's like it runs `nixos-rebuild` using the Pi's `/etc/nixos/configuration.nix` but on another computer, and all the Pi has to do is download the results of the rebuild and run it. In other words, does *exactly* what I needed.

---

I was initially worried that I'd have to make some changes to the Pi's system configuration to deploy it with NixOps, but all I had to do was write a nix expression telling NixOps where to deploy the configuration and some details about the machine architecture, as described in the [user manual](https://releases.nixos.org/nixops/latest/manual/manual.html#sec-deploying-to-physical-nixos).

If you're following this at home, make sure to include *all* your configuration files when you import your existing one, including the `hardware-configuration.nix` file!

```nix
{
  network.description = "Raspberry Pi";
  
  pi3 = { config, pkgs, lib, ... }: {
    deployment.targetHost = "192.168.1.x";
    
    nixpkgs.localSystem = {
      system = "aarch64-linux";
      config = "aarch64-unknown-linux-gnu";
    };
    
    imports = [
      ./pi-configuration.nix
    ];
  };
}
```

To build an arm64 configuration on an x86_64 system you have to enable arm64 emulation, but I already had that set up from when I was using it distributed builds, I think I got it [from here](https://nixos.wiki/wiki/NixOS_on_ARM#Compiling_through_QEMU). In any case, this is all you need to add to your *build machine*'s configuration.

```nix
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```

Then you have to allow your build machine to log into the target machine via SSH as root, install the `nixops` command and it's just a couple of `nixops` commands to create the deployment and send it to the Pi.

```shell
$ nixops create ./rpi.nix -d rpi
$ nixops deploy -d rpi
```

These commands will create a new deployment called `rpi` using the specification file above and deploy it. Not that hard after all!

---

Summing up, NixOS is really nice and you, hypothetical reader who isn't using it, should try it. [All issues with documentation and tooling notwithstanding](https://christine.website/talks/nixos-pain-2021-11-10). Here's a couple things that are tangentially related to this post.

* Thanks to [@cadey](https://christine.website/) and probably a couple others I forget for posting about Nix stuff on Lobsters a lot and getting me to try NixOps out.
* [This is my NixOS configuration](https://kirarin.hootr.club/git/steinuil/nixos-config) if you *really* want to look at it. The Gitea server it's hosted on is defined in one of the configurations in there. Very meta. Maybe one day I'll switch it to NixOps.
* When I wrote "It's a slow machine", it reminded me of the similar line from Penny Lane by The Beatles and the song started playing in my head and it wouldn't stop. Sadly I couldn't think of a way to work it into the post.

Good night.
