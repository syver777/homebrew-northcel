# Homebrew tap for `northcel`

This tap installs [NorthCel](https://github.com/syver777/northcel), the open
drawing language for AI-drawn video, on Linux x86_64.

## Install

```sh
brew tap syver777/northcel
brew trust syver777/northcel        # Homebrew 7+ asks once for third-party taps
brew install northcel
```

`brew install syver777/northcel/northcel` is the same install without the separate
`brew tap` step (the `brew trust` step still applies).

`brew install northcel` without the tap does not work: there is no formula for it
in homebrew-core, and this tap is the supported Homebrew path.

## What it installs

Two Python artifacts go into a private Homebrew venv (`libexec`); nothing is
compiled and nothing is downloaded on first run.

| Artifact | Role |
| --- | --- |
| `northcel` | the reference implementation (parser, validator, formatter, renderer) **and** the launcher — the `northcel` command plus its short alias `ncel` |
| `northcel-native` | the native runtime: a MoonBit stage that parses and builds the IR, **Bend 0.2.38 / HVM 2.0.22** that evaluate `bend_swarm` agents, and **GLSL 4.30** shaders rasterised by a Mesa/EGL (llvmpipe) context |

The Homebrew formula also installs Mesa (`libEGL` + llvmpipe), Python 3.12, NumPy
and Pillow. No GPU is required: rasterisation is software and deterministic.

## Check that it works

```sh
northcel doctor          # every stage, version, shader hash and the platform verdict
northcel verify          # conformance frame + 6-frame film, rendered twice
northcel render scene.ncel -o frame.png
```

`doctor` exits `0` only when the native runtime is genuinely usable; it exits `3`
with the reason when it is not. `verify` renders the pinned conformance frame and
a six-frame film twice and compares the hashes.

## Platform

The native runtime is Linux x86_64 only, glibc ≥ 2.39 (Ubuntu 24.04+, Debian 13,
Fedora 40+, RHEL 10). The formula refuses macOS, Windows and other architectures
rather than installing a launcher that could only use the reference path.

On macOS, install with pip instead:

```sh
python3 -m pip install northcel
```

That gives the same CLI and renders through the Python reference implementation,
which labels every receipt `"renderer": "python-reference"`. It is the conformance
oracle, not the native runtime.

## Upgrade and uninstall

```sh
brew upgrade northcel          # or: brew update && brew upgrade northcel
brew uninstall northcel        # removes the venv, the Cellar entry and both commands
brew untap syver777/northcel   # optional: removes the tap checkout
```

Homebrew keeps the downloaded packages in its own cache (`brew --cache`,
`brew cleanup` clears it). The formula writes nothing outside the Homebrew prefix:
no `~/.local/share/ncel`, no config in `$HOME`.

## Troubleshooting

**`northcel doctor` says `no libEGL.so.1 found`.** The formula sets
`LD_LIBRARY_PATH` to its own Mesa, so this should not happen on a Homebrew
install. If it does, install the distribution's EGL runtime once:

```sh
sudo apt install libegl1 libgl1                 # Debian/Ubuntu
sudo dnf install mesa-libEGL mesa-dri-drivers   # Fedora/RHEL
```

Without any EGL runtime, `brew install` still succeeds and `northcel` says why: it
renders through the labelled Python reference.

**`northcel verify` fails.** Run `northcel doctor` first; it prints the exact stage
that is missing or the version mismatch. Both the failing and expected hashes are
printed by `verify`.

## Licence

The formula and this tap are MIT. The installed packages are dual licensed
`MIT OR Apache-2.0`; the formula declares `license any_of: ["MIT",
"Apache-2.0"]`.
