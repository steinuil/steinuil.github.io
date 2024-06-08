In my last post, I mentioned I'm currently working at a Python shop. I'm also a huge fan of Nix, and I believe that a day may come when we can get rid of the messy deployment setup we use now and replace it with Nix, but it is not this day. Today I'm just gonna talk about how I stealthily manage my development environments for the Python projects at work with Nix and direnv, and how you could easily do the same.

## Who is this for?

You're running NixOS or nix-darwin or home-manager on your computer of choice or maybe you're just trying Nix out, and you just want to get things done at your job.

You don't particularly care about building a reproducible derivation or an image that you can deploy with Nix.

You don't want to spend too much time figuring out why psycopg or some other Python library you don't want to pick a fight with is not building in your current checkout of nixpkgs.

You don't want to install multiple versions of Python on your machine or mess with the tooling that should take care of that for you.

You want to keep things clean.

## What do we want?

Since this is a work project, let's talk requirements!

- We shouldn't make any changes to the repositories; we don't want to go around dropping files in every team's repos if they don't want to buy into the tooling.

- We don't have to go all-in on Nix. Debugging a failing build of a Python package for a repo we don't touch all that often sucks and it adds too much overhead.

- Related to the previous point, the setup should be very similar to the one your team members are using.

In short: don't rock the boat. There's a time and a place for introducing tooling, and it is not now. We just want a working setup that succeeds in providing a Python development environment, without littering our global environment.

## The flake

The flake where I keep my dev environments looks kind of like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
  	flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        mkPythonShell = python:
          pkgs.mkShell {
            name = "python-${python.version}";
            buildInputs = [
              pkgs.pyright
              pkgs.ruff
              pkgs.poetry
              (python.withPackages (ps: [
                ps.black
                ps.flake8
              ]))
            ];
          };
      in
      {
        devShells = {
          python39 = mkPythonshell pkgs.python39;
          python310 = mkPythonShell pkgs.python310;
          python311 = mkPythonShell pkgs.python311;
          python312 = mkPythonShell pkgs.python312;
        };
      }
    );
}
```

I keep one devShell for each version of Python, and only install tools that are required for Python development but are not specified in the project dependencies so they don't litter my `$PATH` when I'm not using them. I prefer to keep this package set small so that it breaks less often.

To use it, you're gonna have to create a new git repository, dump the code above in a `flake.nix`, and then run `nix flake lock`. You can also try running one of the shells with `nix develop .#python312` to make sure that everything is working correctly.

This flake is freestanding and lives outside of any existing repos, and if you manage to convert some coworkers to Nix it can be pushed to the company's git forge of choice.

## The .envrc

[direnv](https://direnv.net/) is a wonderful tool and if you're not using it yet, you should check it out. It installs a hook inside your shell that runs when you change directories, and when it detects that an `.envrc` file is present in the current directory or further up the tree, it runs the commands specified in that `.envrc` file and updates the env variables accordingly. This means that you can set env variables, add executables to your `$PATH` and, crucially, set your Python venv automatically.

This `.envrc` is a simple shell script that is executed with some predefined utility commands (the [stdlib](https://direnv.net/man/direnv-stdlib.1.html)). These include loading `.env` files with `dotenv` and automatically setting the correct interpreter version and installing dependencies for several languages. We don't need most of that though, because the Nix dev environment manages the Python version for us.

If you're using `home-manager`, the installation is as easy as:

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
}
```

`nix-direnv` is absolutely required when you're working with flakes. Without it, it may take several seconds to `cd` into the project directory. With `nix-direnv`, loading previously cached flakes will take less than a second.

To drop into one of the Python shells we created in our flakes, create an `.envrc` file in the root of a repository containing this:

```shell
use flake ../path/to/flake#python310
```

(The path/to/flake can be [anything that is accepted as a flake URL](https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix3-flake.html#examples): a relative path from your current directory, a git repository on github or your employer's git forge, or a URL that points to a tarball.)

Then close the file, run `direnv allow`, and you should see Nix preparing a dev environment containing the Python 3.11 interpreter and all the tools we specified in the flake. This might take a while the first time you do it, but after the initial setup it'll be instantaneous. Try it out!

```
$ cd project
direnv: loading project/.envrc
direnv: using flake ../path/to/flake#python310
direnv: nix-direnv: using cached dev shell
direnv: export +AR +AS +CONFIG_SHELL ...
$ black --version
black, 24.4.2 (compiled: yes)
Python (CPython) 3.10.13
$ python -V
Python 3.10.13
$ cd ..
direnv: unloading
$ black --version
bash: black: command not found
$ python -V
Python 3.9.6
```

The `.envrc` file should live at the root of your project, but if you don't want to check it into git or add it into `.gitignore` you can sneakily add an ignore for it inside your project's `.git/info/exclude`.

```gitignore
.direnv/
.envrc
```

Now if you run `git status`, you won't see any added files!

## The venv

For reasons I won't go into here, we're still using `pip` and good old `requirements.txt` files to specify dependencies rather than `poetry` or any of the fancy new Python tooling. To simplify this dev environment setup and keep it close to our coworkers', we're gonna use normal Python tooling to set up the virtual env and install dependencies.

1. First of all, create the venv.
   ```shell
   python -m venv venv
   ```

2. Then add these lines to your `.envrc` to make `direnv` load the venv. (I added the `VIRTUAL_ENV_DISABLE_PROMPT` bit because it messes up my Starship prompt, but you may want to keep it.)
   ```shell
   export VIRTUAL_ENV_DISABLE_PROMPT=1
   source venv/bin/activate
   ```

3. Enter the venv by allowing the changes you made to your `.envrc`.
   ```shell
   direnv allow
   ```

4. Now that you're inside the venv, upgrade `pip` and `setuptools` and install `wheel`. (Imma keep it real with you: this is just cargo culting. I don't actually know how much of this is needed. Feel free to @ me for this one.)
   ```shell
   pip3 install --upgrade pip setuptools
   pip install wheel
   ```

5. Let's get installing!
   ```shell
   pip install -r requirements.txt
   ```

## Tell yourself this is fine

Is this really it? Is this what my life is right now? Setting up non-reproducible development environments, deploying a service mesh using brittle tooling that is not made to deploy service meshes, writing boring code in a boring language using boring tools, and earning your paycheck at the end of the month?

Well, my friend, maybe it is fine. You know better, and that's a good asset to have in the right environment. Maybe you can be the person that brings positive technical change inside the company and get recognition for it. You can do it.

## The end

Repeat this for every Python repository you might have at your company. That's it! You can start working on the actual tasks in your sprint now.

