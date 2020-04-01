# The journey of packaging a .NET app on Nix

Me and a few friends have a Discord server where we all gather once a week (or even two lately, due to recent events) to watch a movie together. It's been going on for about three and a half years and we thought it'd be about time to make a bot that handles voting and backlog and times for us, so we started writing one, in F#.

My Raspberry Pi running NixOS is on 24/7, so I thought I could run the bot from there and learn something about packaging on Nix while doing so.

**Disclaimer**: I have very little experience with packaging in Nix. If you spot any mistakes please tell me and I'll correct them!

---

First I thought I could cross-compile the bot and then just run the compiled version, so I wouldn't have to bother with packaging the dependencies. Cross-compiling a .NET Core/5.0 program using the `dotnet` cli is very easy, you just have to specify the [runtime identifier](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog) and use the `--self-contained` switch so the target machine doesn't need to have the .NET runtime installed.

```shell
$ dotnet publish --self-contained -r linux-arm64 -c Release
```

I sent the output to the pi and inspected it with `ldd`. Running binaries on NixOS is [not as easy](https://nixos.wiki/wiki/Packaging/Binaries) as on other Linux distros, because the paths to the dynamically loaded libraries are completely different compared to other distros.

I tried to patch the binary with `patchelf` but didn't have much luck; even when I did manage to make it run it just printed this message:

```
No usable version of libssl was found
```

And then dumped core. I decided to just do it the hard way.

## The first derivation

I cloned the repository on the Pi and quickly discovered that the `dotnet-sdk` package did not support arm64. This was easy enough to fix; I downloaded the .nix file and modified the URL and the hash to point to the `linux-arm64` version of the SDK. (I promise I'll upstream support for arm64 eventually, but for the moment it's just on my machine.)

It worked well enough; I could build the bot. So I tried to make a simple derivation for it.

```nix
{ stdenv, libunwind, openssl, icu
, libuuid, zlib, curl, callPackage
, dotnet-sdk }:
let
  rpath = stdenv.lib.makeLibraryPath [
    stdenv.cc.cc libunwind libuuid icu
    openssl zlib curl
  ];
  
  dynamicLinker = stdenv.cc.bintools.dynamicLinker;
in stdenv.mkDerivation rec {
  pname = "kino-bot";
  version = "2020-03-29";
  
  src = builtins.fetchGit {
    name = "${pname}-${version}-git";
    url = https://github.com/steinuil/KinoBot;
    ref = "master";
    rev = "275ae0447ab1ab21cba76bb673f00559ed5d9251";
  };
  
  buildInputs = [ dotnet-sdk ];
  
  buildPhase = ''
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export HOME="$(mktemp -d)"
    dotnet publish --nologo \
      -r linux-arm64 --self-contained \
      -c Release -o out
  '';
  
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r ./out/* $out
    ln -s $out/KinoBot $out/bin/KinoBot
    runHook postInstall
  '';
  
  dontPatchELF = true;
  postFixup = ''
    patchelf --set-interpreter "${dynamicLinker}" \
      --set-rpath '$ORIGIN:${rpath}' $out/KinoBot
    find $out -type f -name "*.so" -exec \
      patchelf --set-rpath '$ORIGIN:${rpath}' {} ';'    
  '';
  
  meta = with stdenv.lib; {
  	homepage = https://github.com/steinuil/KinoBot;
  	platforms = [ "aarch64-linux" ];
  	license = licenses.isc;
  };
}
```

(I took inspiration from [this gist](https://gist.github.com/jb55/b8b49893e18b61fb8c3ea3c924358278) and a few other derivations I found to come up with this.)

So I tried to run it:

```
$ nix repl '<nixpkgs>'
Welcome to Nix version 2.3.3. Type :? for help.

Loading '<nixpkgs>'...
Added 10863 variables.

nix-repl> kino-bot = callPackage (import ./kino-bot.nix) {}

nix-repl> :b kino-bot
```

But it got stuck on the `dotnet restore` step of the build. I discovered that external connections are not allowed during the build step of a Nix derivation, so I had to fetch the dependencies *through Nix*.

## Packaging the dependencies and a digression on base32 hashes

It turns out the `dotnet` command takes a `--source` argument which lets you specify a folder containing the NuGet packages.  I started by copying the [aforementioned gist](https://gist.github.com/jb55/b8b49893e18b61fb8c3ea3c924358278), which got the list of all direct and transitive dependencies from the `obj/project.assets.json` file. I didn't want to install Node though, so I rewrote the script in F#.

There's a problem with the script though: the dependencies file specifies a base64-encoded sha512 hash which doesn't correspond to the hash of the zip file, and probably not to the [Nix serialization of the path](https://www.mankier.com/1/nix-hash) either.

The hashes that Nix uses are also not at all like the ones you see in the wild; they use too many characters for hex, but also too few for base64. In fact Nix uses its own version of base32, more compact than base16 but still only containing ASCII digits and lowercase letters (except e o u t, which were chosen [to reduce the chance of the hash containing swearwords](https://discourse.nixos.org/t/no-hashes-starting-with-e-t-o-or-u-in-nix-store/4906/7)). The implementation is specified in [src/libutil/hash.cc](https://github.com/NixOS/nix/blob/master/src/libutil/hash.cc#L76) and it's very compact and easily ported to other languages. This is my F# implementation:

```F#
module Base32

let chars = "0123456789abcdfghijklmnpqrsvwxyz"

let length size =
    (size * 8 - 1) / 5 + 1

let fromBytes (bytes : byte[]) =
    seq {
        for n = length bytes.Length - 1 downto 0 do
            let b = n * 5
            let i = b / 8
            let j = b % 8
            yield int bytes.[i] >>> j ||| if i >= bytes.Length - 1 then 0 else int bytes.[i + 1] <<< (8 - j)
    }
    |> Seq.map (fun c -> chars.[c &&& 0x1f])
    |> Seq.toArray
    |> System.String
```

But let's go back to the dependencies. After some head scratching because `nix-hash` returned a different hash for a dependency downloaded through curl than for one downloaded through `nix-prefetch-url` I figured I just had to pass the `-L` flag to curl to follow the redirect.

```shell
$ nix-prefetch-url https://www.nuget.org/api/v2/package/Argu/6.0.0
[0.2 MiB DL]
path is '/nix/store/rn0qb89ibmn3xv7ay28309r0wj3xaf5q-6.0.0'
1zybqx0ka89s2cxp7y2bc9bfiy9mm3jn8l3593f58z6nshwh3f2j

# WRONG: this will download the redirect HTML page. Pass -L to curl to fix.
$ curl -o Argu.6.0.0.zip https://www.nuget.org/api/v2/package/Argu/6.0.0
$ nix-hash --type sha256 --flat --base32 ./Argu.6.0.0.zip
04w8jx2wzss3y2c9bx6dm6lxib03v2jnr89iakcgk93zippfxb0w
```

And there I was with my newly created [discourse.nixos.org](https://discourse.nixos.org/) account ready to send a post demanding explanations. Oh well!

I had to also write my own version of `fetchNuGet` because the default one tried to build the artifacts again for some reason, didn't support sha512, and used mono which I'm not using. I used the same gist as above for inspiration.

```nix
{ baseName, version, sha512 }:
  let nupkgName = lib.strings.toLower "${baseName}.${version}.nupkg"; in
  stdenvNoCC.mkDerivation {
    name = "${baseName}-${version}";
    
    src = fetchurl {
      inherit sha512;
      url = "https://www.nuget.org/api/v2/package/${baseName}/${version}";
      name = "${baseName}.${version}.zip";
    };
    
    sourceRoot = ".";
    
    buildInputs = [ unzip ];
    
    dontStrip = true;
    
    installPhase = ''
      mkdir -p $out
      chmod +r *.nuspec
      cp *.nuspec $out
      cp $src $out/${nupkgName}
    '';
  }
```

The `nuget2nix` script generates a file that looks roughly like this:

```nix
name: rec {
  cache = linkFarm "${name}-nuget-pkgs" packages;
  packages = [
    { name = "Argu";
      path = fetchNuGet {
       baseName = "Argu";
       version = "6.0.0";
       sha512 = "1kiqh4zpasydq5vx4wn5mal5v8c2bdalczja5za9phvq8n9c3s453lj5kmrqar1rfp3504kakb5csxflj7dwy2aas04d0jjw9dhm9g2";
      };
    }
    ...
  ]
}
```

The `linkFarm` function, which is only documented in a [comment in the source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders.nix#L303) (Nix has a recurring problem with documentation, yes) takes every derivation in its second arguments and links it as a subdirectory into a derivation named after the first, which is exactly what I needed for the `--source` directory in the restore step of the build.

Before going back to the main file, a few protips about the packages, because these thing got me stuck for a while:

- If you source the packages from your [lockfile](https://devblogs.microsoft.com/nuget/enable-repeatable-package-restores-using-a-lock-file/) you will have to set the `RuntimeIdentifiers` property in your `.[cf]sproj`, or else you'll be missing some platform-specific ones like `runtime.native.System.Security.Cryptography.OpenSsl`.
- Make sure you don't download the same dependency twice, or you'll get an error in the `ln` phase of the `linkFarm` derivation saying "Permission denied".
- There's a few dependencies listed under `project.frameworks.<yourTargetFramework>.downloadDependencies` in the `obj/project.assets.json` file that you'll also have to include in the build. These are the ones called like `Microsoft.NETCore.App.Runtime.linux-arm64` and so on.

## Finally running the bot

Nothing much has changed in the main derivation. I just added the link farm derivation to the list of dependencies and set it as source in the `dotnet publish` command.

```nix
let
  rpath = ...;
  nugetPkgs = callPackage (import ./kino-bot-nuget.nix) {} "kino-bot";
in stdenv.mkDerivation rec {
  ...

  buildInputs = [ dotnet-sdk nugetPkgs.cache ];

  buildPhase = ''
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export HOME="$(mktemp -d)"
    dotnet publish --nologo \
      -r linux-arm64 --self-contained \
      --source #{nugetPkgs.cache} -c Release -o out
  '';

  ...
};
```

After all this I could finally build the package locally, but when I tried to run it I got the same libssl error as in the beginning. Was this all for naught? (Maybe it was.)

Turns out .NET Core [only supports version 1.0 of openssl](https://stackoverflow.com/questions/51901359/net-core-2-1-sdk-linux-x64-no-usable-version-of-the-libssl-was-found), and the version packaged by Nix is 1.1. This is easily fixed by importing `openssl_1_0_2` instead of `openssl`.

```nix
   rpath = stdenv.lib.makeLibraryPath [
     stdenv.cc.cc libunwind libuuid icu
+    openssl_1_0_2 zlib curl
-    openssl zlib curl
   ];
```

## Adding the package to your system

Now that I got it running I had to add it to the system, and to do this you have to add an [overlay](https://nixos.wiki/wiki/Overlays). An overlay is just a function that takes two arguments, named self and super, and returns a set of packages. This is what mine looks like:

```nix
self: super: {
  dotnet-sdk = super.callPackage ./pkgs/dotnet-sdk.nix {};
  kino-bot = super.callPackage ./pkgs/kino-bot.nix {};
}
```

Then you need to import it to the main `configuration.nix` file. (Note the parenthesis around the import: Nix will throw [a cryptic infinite recursion error](https://discourse.nixos.org/t/infinite-recursion-encountered-at-undefined-position/3039/13?u=steinuil) with no stack trace if you forget them!)

```nix
nixpkgs.overlays = [ (import ./my-overlay.nix) ];

environment.systemPackages = with pkgs; [
  ...
  kino-bot
];
```

I also added a systemd service to start it automatically.

```nix
systemd.services.kino-bot = {
  enable = true;
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Restart = "on-failure";
    ExecStart = "${pkgs.kino-bot}/bin/KinoBot --token ${secrets.kinoBotToken}";
  };
};
```

---

This took me a few days to get working, and I had to rebuild everything dozens of times to get it working. I omitted several dumb mistakes I made and only kept in those that I had the most trouble with because I thought they could help others.

Nonetheless, I really like NixOS and I'll definitely be using it more and package more things in the future. It's already my main Linux OS on my (personal) laptop and my Raspberry Pi (I use Windows on my desktop and work laptop, sadly) and this was a good occasion to learn more about how its packages work. I'll probably be migrating my server to it too in the future.

[Code for this post here](https://gist.github.com/steinuil/11c7565253e4af03658f59c9c331d268). *Note: there's many hacks specific to my use-case left in the code and it's probably not usable as-is.*

## Further reading

- [Nix pills](https://nixos.org/nixos/nix-pills/index.html)
- [Nixpkgs manual](https://nixos.org/nixpkgs/manual/)