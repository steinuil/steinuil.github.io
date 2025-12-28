+++
title = "My Immich setup feat. NixOS"
date = 2025-10-03

[taxonomies]
tags = ["nix", "immich"]
+++

[Immich reached a stable release!](https://github.com/immich-app/immich/releases/tag/v2.0.0) I started using it several months ago and I've been having a very pleasant experience with it, so I figured I could write a few lines about it.

[Immich](https://immich.app/) is an open source self-hosted replacement for Google Photos and other similar paid services. It has a very polished web UI and mobile apps. This is what it looks like:

![A screenshot of my instance of Immich, featuring photos of my keycaps, my newly installed kitchen knife rack, and some pigeons sleeping on a power line](ui.png)

Basically you slap it on your home server, upload your photos, and you get all the good parts of a photo hosting service without selling your soul and throwing away your privacy! *For free!!* Free unless you're counting hardware and electricity bills that is, but then again, once you have a home server to run Immich you can use it to run [all](https://www.navidrome.org/) [sorts](https://transmissionbt.com/) [of](https://jellyfin.org/) [cool](https://syncthing.net/) [software](https://github.com/dani-garcia/vaultwarden).

It is licensed under the AGPL and the people behind [the company that maintains it](https://futo.org/) seem to have a strong commitment to privacy and open source. Immich uses several (optional) ML-powered features like facial recognition, contextual search, and duplicate detection, all of which run locally. (This is what I like to call _"one of the few useful uses of AI."_) As far as I can tell, Immich does not "phone home" or contact the external world on its own.

If you snoop around on the website you'll see a "[Purchase](https://buy.immich.app/)" link, and you'd be forgiven for thinking that this is a Freemium™ product that paywalls some features. But it's not! If you "buy" Immich all you get is a badge showing that you're a supporter on the web UI. You'll notice that I have the badge in my screenshot: I was so impressed with Immich after using it for a few weeks that I figured I should show my support in some way. For the 2.0.0 release they've also started selling some branded clothes and [an actual demo disk](https://immich.store/en-eur/products/immich-retro) on their store, which I think is just lovely.

(If this sounds a lot like shilling, I can assure you I'm not related to the Immich project or FUTO in any way. I'm just a happy user.)

## Why I'm running Immich

The short answer is I like self-hosting and open source software and I don't like Google. I'm self-hosting a bunch of other things, some of which I linked above.

{% note() %}
Actually I'm not running [Jellyfin](https://jellyfin.org/) yet, but I'd like to do so in the near future. I'm planning to upgrade the mainboard of my [Framework 13" laptop](https://frame.work/) and place the old one in [a case](https://frame.work/products/cooler-master-mainboard-case) which will go on my home "rack", and take some of the load off my Raspberry Pi. That poor thing can't handle transcoding movies.

Also, my partner wants me to set it up so they can watch the movies by [Nanni Moretti](https://letterboxd.com/director/nanni-moretti/) I have sitting on my home server when they're not at my place. But I'm getting ahead of myself.
{% end %}

The long answer involves several old hard drives with photos recovered from dead phones and busted cameras, and still-working phones bursting with photos. The latter are my partner's and my mother's phones. Both of them were often complaining about how they couldn't download a file or take another photo because their phones' storage had run out of space, and I, the most Computer Person of the family, would have to regularly swoop in and save the day by deleting some old files and apps they weren't really using. The old hard drives are my own, and I wasn't keen on losing those old memories.

All of us had photo library problems, and something had to be done.

## Setting up Immich on NixOS

...is really easy. On [the Lobste.rs thread](https://lobste.rs/c/ldgtdn) of the announcement, [Michael stapelberg](https://michael.stapelberg.ch/) commented that it's as easy as adding this snippet to your NixOS config:

```nix
{
  services.immich = {
    enable = true;
    host = "photos.example.ts.net";
  };
}
```

[My setup](https://kirarin.hootr.club/git/steinuil/flakes) is a bit more complicated than that. First of all I dedicated a spare hard drive to it, which is mounted to Immich's service directory. The `wantedBy` rule ensures that Immich can only run after the drive has been mounted.

```nix
{
  systemd.mounts = [
    {
      type = "ext4";
      what = "/dev/sdb2";
      where = "/var/lib/immich";
      wantedBy = [
        "immich-server.service"
      ];
    }
  ];
}
```

Immich has several features that depend on [machine learning](https://docs.immich.app/features/ml-hardware-acceleration), which is cool but definitely not something the Raspberry Pi I'm running it on can handle! Luckily for the poor Pi, you can [run the ML service on another computer](https://docs.immich.app/guides/remote-machine-learning) and configure Immich to use it, so this is what my actual Immich config looks like:

```nix
{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    machine-learning.enable = false;
  };
}
```

The ML service runs on my much beefier desktop. NixOS's Immich module [doesn't currently support](https://github.com/NixOS/nixpkgs/issues/436487) running the ML service separately from Immich, so I had to write my own module for this. You can find the full module [here](https://kirarin.hootr.club/git/steinuil/flakes/src/commit/ca508fe53af0edd87d0966f900e6d036a616b671/modules/nixos/immich-ml/default.nix) (which someday I will try to upstream), but just to give you an idea:

```nix
{
  # module options elided for brevity

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.immich-ml = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        IMMICH_HOST = cfg.host;
        IMMICH_PORT = toString cfg.port;
        MACHINE_LEARNING_CACHE_FOLDER = "/var/cache/immich-ml";
        IMMICH_MACHINE_LEARNING_WORKERS = toString cfg.workers;
        IMMICH_MACHINE_LEARNING_WORKER_TIMEOUT = toString cfg.workerTimeout;
        MPLCONFIGDIR = "/var/lib/immich-ml";
      };
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        StateDirectory = "immich-ml";
        CacheDirectory = "immich-ml";
        DynamicUser = true;
        # some hardening and nvidia-related options...
      };
    };
  };
}
```

{% note() %}
I never got it to use my GPU for the ML tasks. There is [an issue on nixpkgs](https://github.com/NixOS/nixpkgs/issues/418799) about this which was closed 2 weeks ago, so I'll have to check the next time I update my flake inputs.

And by the way, if you go look at the service definition in my flake you'll see that it's supposed to be a socket-activated service, but I'm not sure that it's working as it's supposed to. Someone who is good at the systemd please help me fix this. ~~my family is dying~~
{% end %}

After this you can go on Immich and navigate to **Administration** > **Settings** > **Machine Learning Settings** to add the URL of your ML worker machine.

I also set up backups. Backups are super important because I'm not the only user. My partner would be quite sad if I lost their photos due to a busted drive.

I'm using [restic](https://restic.net/) and backing up to [Backblaze B2](https://www.backblaze.com/cloud-storage) and another drive, for safety. In my configuration I'm using a helper module I wrote that sources the secrets, repository, and password from files set up by [sops-nix](https://github.com/Mic92/sops-nix), but this is the moral equivalent:

```nix
{
  services.restic.backups.immich = {
    paths = [
      "/var/lib/immich"
    ];
    # The environment file should contain:
    # AWS_ACCESS_KEY_ID=<key_id from the B2 bucket>
    # AWS_SECRET_ACCESS_KEY=<key_secret from the B2 bucket>
    environmentFile = "/super/secret/environment-file";
    passwordFile = "/super/secret/password-file";
    repository = "<repository>/<bucket name>";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
```

Finally, I used a [Tailscale Funnel](https://tailscale.com/kb/1223/funnel) to expose it to the internet, so that my relatives could use it without setting up Tailscale on their devices. I wrote a very simple service to take care of this:

```nix
{
  systemd.services.tailscale-funnel-immich = {
    description = "Tailscale Funnel forwarding for Immich";

    # https://old.reddit.com/r/Tailscale/comments/ubk9mo/systemd_how_do_get_something_to_run_if_tailscale/jia3pwn/
    after = [
      "sys-subsystem-net-devices-tailscale0.device"
      "tailscaled.service"
      "immich-server.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.ExecStart = "${lib.getExe config.services.tailscale.package} funnel ${builtins.toString config.services.immich.port}";
  };
}
```

And that's it! I've only ever had two issues with this setup.

- Every once in a while, the Tailscale session on my Pi expires and that makes the funnel inaccessible... I should probably set up some sort of notification for that.
- I don't run upgrades on the Pi very often, so I ran into a [migration issue](https://docs.immich.app/errors/#typeorm-upgrade) that only happened if you skipped versions between v1.132.3 and v1.137.0. To fix it I had to pin a version of nixpkgs that packaged an intermediate version of Immich, deploy it on the Pi, wait for it to migrate, and then upgrade again to the latest version.

Overall it's been a very low maintenance setup.

## Using Immich

I'm sure you could tell from the introduction of this post, but I think Immich is really good! My partner uploaded all their photos and they're very happy with it. Unfortunately at some point my mother caved in to the pressure and subscribed to Google One, and I still haven't bothered to talk her out of it.

I have uploaded all of my photos to it, an archive going back to 2014. The web UI makes it easy and quick to scroll and jump around the timeline; it has brought me back to many good memories. I also like the actual "memory" feature which finds photos you took on the same calendar day the previous years and shows them on top of the gallery. I haven't used any software to organize my photos since [Picasa](https://en.wikipedia.org/wiki/Picasa) was still a thing. Immich made me remember how nice that can be.

There's a lot of other things I enjoy so I'll quickly go through them in a list:

- The reverse geocoding features are fun and useful. I like how I can see all the places I've taken photos in plotted on a map, and it's helped me remember holidays and good restaurants.
- Maybe this tells you more about me than about Immich, but the [contextual CLIP search](https://docs.immich.app/features/searching) kinda feels like magic. I can just search for "cat" and it'll show me all the cat photos I've ever taken! Unbelievable.
- Facial recognition requires some manual fixing sometimes, but I like it! It's fun to see how my friends used to look like 8 years ago.
- You can share albums between different users and also create external links with an expiration date that allow anybody with the link to upload their photos. I used this a bunch of times to share photos with friends I went on vacation with.
- This is not exactly a feature of Immich itself, but I like that the team behind Immich shares the "cursed knowledge" they came across while building Immich [on a page on the website](https://immich.app/cursed-knowledge).

In conclusion: I think you should give Immich a try! Don't let big corporations use your memories as training data for their torment nexi. Take control of your data. There are alternatives for most of the services you use regularly and they're actually really nice. Support those instead of throwing money at a subscription service.

Thank you for reading, have [a song I like](https://soundcloud.com/sozenotsubo/kioku).
