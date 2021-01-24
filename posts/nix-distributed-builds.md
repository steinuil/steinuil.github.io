I have a Raspberry Pi 3 sitting next to my router, from which I host a couple things to my local network. I installed NixOS on it and I love the experience: it completely removes the absolute nightmare that is configuring a Linux machine, and I find that incredibly liberating.

But there's a catch: the Pi is slow and it doesn't have a lot of memory. Just evaluating the configuration with `nixos-rebuild` takes about a minute even when there haven't been any changes, and compiling anything substantial is usually a recipe for Death By Swap.

The other day I tried updating the main [channel](https://nixos.wiki/wiki/Nix_channels) (the package repository) and upgrading my packages with `nixos-rebuild switch --upgrade` and found out that one of the packages I was using wasn't available on the main [binary cache](https://nixos.wiki/wiki/Binary_Cache) at `cache.nixos.org` anymore, so it had to be built locally. The program in question is written in Rust and has a pretty sizeable dependency graph. I left it to build overnight. The morning after it was still stuck on building one of the sub-packages, and I couldn't even open a new ssh connection to the Pi.

There's a couple solutions to this:

- Build the program on another machine and add a new package that just fetches this binary and patches it
- Setting up a binary cache on another machine
- Setting up distributed builds

The first one is an ugly hack (in Nix terms, at least) and would probably end up being more trouble than it's worth.

The second option, setting up another binary cache, is definitely better.  The [wiki page](https://nixos.wiki/wiki/Binary_Cache) does a good job of explaining how to set up the server, and on the client you just need to add a couple lines to your `configuration.nix` to enable it:

```nix
  nix.binaryCaches = [ "http://<server url>" ];
  nix.binaryCachePublicKeys = [ "<the cache's public key>" ];
```

The downside is that you have to know beforehand which packages you need to build, and not being very well-versed in Nix I couldn't figure out how to build the specific versions I needed. 

So we're left with the third option, distributed builds. The [wiki page](https://nixos.wiki/wiki/Distributed_build) opens with this paragraph:

> Sometimes you want to use a faster machine for building a nix derivation you want to use on a slower one. If you have ssh access to a machine where Nix (not necessarily NixOS) is installed, then you can offload building to this machine. 

Which seems to be exactly what I'm looking for.

The wiki mentions a couple options to add in `configuration.nix` to enable offloading builds to the client. I used these on the Pi:

```nix
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "builder";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }
  ];
  programs.ssh.extraConfig = ''
Host builder
  HostName <url of the host>
  Port 2222
  User builder
  IdentitiesOnly yes
  IdentityFile /root/.ssh/id_builder
  '';
```

I created the key in `/root/.ssh/id_builder` using the options recommended in [this Stack Exchange answer](https://security.stackexchange.com/a/144044) (not that it matters since it's all on my local network):

```
# ssh-keygen -t ed25519 -a 100 -f /root/.ssh/id_builder
```

For the host machine I had to go with emulation, since I don't have another ARM64 machine lying around. My beefy desktop runs Windows so I created a VirtualBox machine with 4 cores, 8GB of memory, and a couple GB of hard drive space to store the build results. Setting up emulation was incredibly easy after finding [the NixOS on ARM wiki page](https://nixos.wiki/wiki/NixOS_on_ARM#Compiling_through_QEMU), all it takes is one line in the VM's `configuration.nix`:

```nix
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

Then I had to activate OpenSSH with `services.openssh.enable = true;`, add the Pi's public key to `/home/builder/.ssh/authorized_keys`, forward the SSH port on the VM to 2222, and open that port in the Windows firewall.

To test that it's working you can try building a package on the client with the `max-jobs` option set to 0.

```
nix-build -j0 --expr 'with import <nixpkgs> {}; callPackage ./default.nix {}'
```

I'm really surprised by how simple all of that was. Setting up a VM that automatically builds packages for another machine while emulating another architecture sounds like a nightmare, but with NixOS it's a couple lines of configuration.

And in case you're wondering, yes, it worked beautifully, and even though the emulation slows things down quite a bit it's still much faster than building things directly on the Pi.
