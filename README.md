# Homebrew tap for NorthCel (.ncel)

NorthCel lives at **https://github.com/syver777/northcel** (source, docs,
releases; also the formula's `homepage`), with the product page at
https://northnoir.com/northcel. This repository only carries the Homebrew formula.

`northcel` is the drawing language CLI for AI-drawn video: a `.ncel` scene is
parsed by a MoonBit typed-AST stage, its swarms are evaluated by Bend 0.2.38 /
HVM 2.0.22, and the contours are rasterised by GLSL 4.30 on Mesa's llvmpipe
through EGL — CPU only, no GPU. The Python reference parser/renderer installs
alongside as the conformance oracle.

```sh
brew tap syver777/northcel
brew trust syver777/northcel        # Homebrew 7+ asks once for third-party taps
brew install northcel

northcel doctor    # MoonBit, Bend/HVM2, GLSL and exact versions
northcel verify    # conformance frame + a six-frame film, rendered twice
```

`brew install syver777/northcel/northcel` is the same install without the
separate `brew tap` step (the `brew trust` step still applies).

`brew install northcel` **without** the tap is not available: homebrew-core does
not accept a new formula without maintainer review.

## What it installs

Everything goes into a private Homebrew venv (`libexec`); **nothing is compiled
and nothing is downloaded on first run**:

| Artifact | Size | Role |
| --- | ---: | --- |
| `northcel` 0.2.1 (sdist) | 142 KB | Python reference parser/validator/formatter/renderer — the conformance oracle, `fmt`, `--no-native` |
| `ncel` 0.2.1 (wheel) | 50 KB | the launcher (`northcel`): platform verdict, native dispatch, doctor/verify/check/info/render/film |
| `ncel-native` 0.2.1 (`manylinux_2_39_x86_64`) | 2.8 MB | MoonBit stage, Bend 0.2.38, HVM 2.0.22, the EGL GL host, both GLSL shaders |
| `setuptools` 84.2.1, `wheel` 0.48.0 | 0.9 MB | build tools for the pinned sdist |
| `numpy` 2.5.4, `pillow` 13.0.0 | 22 MB | required by the reference renderer |

Dependencies: `python@3.12` (the pinned wheels are `cp312`) and `mesa` (libEGL +
llvmpipe — GLSL is compiled by the GL driver, so Mesa *is* the GLSL runtime).

The formula points `LD_LIBRARY_PATH` at `formula_opt_lib("mesa")`, so the Mesa
that Homebrew installs is the one actually loaded. `doctor` reports it
(GL 4.6, Mesa 26.2.6, llvmpipe); it does not silently borrow the distribution's
Mesa.

`northcel` is the only install name; `ncel` is the short command alias the
package itself installs. Both run the same launcher. Installed size: 88.6 MB.

## Platform support

| Platform | Status |
| --- | --- |
| Linux x86_64, glibc >= 2.39 (Ubuntu 24.04+, Debian 13, Fedora 40+, RHEL 10) | **supported, tested** |
| Linux x86_64, glibc < 2.39 | refused: the native wheel is `manylinux_2_39` |
| Linux aarch64 | refused: only `depends_on arch: :x86_64` artifacts exist |
| macOS / Windows | refused: `depends_on :linux` + `depends_on arch: :x86_64` |

The formula refuses rather than installing something that cannot render. The
native runtime has never been built or verified on macOS: Apple's OpenGL stops
at 4.1, so the 4.30 shader cannot compile there; a macOS phase needs
Vulkan/MoltenVK or a tested GL 4.1 path first. `pip install ncel` still works on
macOS and labels its output as the non-native Python reference.

## Status of testing (2026-11-04)

Run on Ubuntu 24.04 x86_64, glibc 2.39, Homebrew 7.0.12, no sudo:

| Step | Result |
| --- | --- |
| `brew tap` + `brew install northcel` | pass — 19 s build step, 88.6 MB |
| `northcel version` / `ncel version` | `ncel 0.2.1 (native runtime 0.2.0, spec 0.2.0-draft, native)` |
| `northcel doctor` | exit 0, 13/13 bundle checksums, GL 4.6 Mesa 26.2.6 |
| `northcel verify` | 5/5 PASS, conformance sha256 `be0eb036…` = pinned |
| `northcel render` (bundled starter) | pass — 320×180, sha256 `b0bf8a78…` |
| `brew reinstall` | pass, same result |
| `brew uninstall` | removes the Cellar entry and both commands; nothing left in `$HOME` |
| `brew audit --strict --formula`, `brew style`, `brew test northcel` | pass (run in the official `ghcr.io/homebrew/brew:latest` container because this VM has no C compiler or Ruby headers for Homebrew's dev gems) |

## Troubleshooting

`northcel doctor` says `no libEGL.so.1 found`: the launcher's platform probe in
`ncel` 0.2.1 only searches the distribution's standard library paths and
`ldconfig -p`; it does not read `LD_LIBRARY_PATH`, so Homebrew's Mesa is
invisible to that probe even though the GL host uses it. Install the
distribution's EGL runtime once (`sudo apt install libegl1 libgl1` on
Debian/Ubuntu, `sudo dnf install mesa-libEGL mesa-dri-drivers` on Fedora/RHEL)
and the native path turns on. Without any EGL runtime the formula still installs
and `northcel` degrades honestly to the labelled Python reference.

## Uninstall

```sh
brew uninstall northcel        # removes the venv and both commands
brew untap syver777/northcel   # optional: removes this tap checkout
```

Homebrew keeps the downloaded wheels in its own cache (`brew --cache`;
`brew cleanup` clears it). The formula writes nothing outside the Homebrew
prefix: no `~/.local/share/ncel`, no config in `$HOME`.

## Upgrading and maintenance

`Formula/northcel.rb` pins the version, the sdist and all six wheels by sha256.
A bump changes the `url`/`sha256` pair, every resource hash and the version
assertion in `test do`; `brew audit --strict --formula northcel` and
`brew style Formula/northcel.rb` must pass before pushing.

`northcel-native` does not exist on PyPI yet (checked 2026-11-04): the published
0.2.1 artifacts are `ncel`, `ncel-native` and `northcel`. The owner naming rule
is one install name, `northcel`, so once 0.2.2 publishes `northcel` (reference +
launcher) and `northcel-native`, this formula collapses to two resources and the
install command does not change.

## Licence

The tap metadata (this repository) is MIT. The installed artifacts are dual
licensed `MIT OR Apache-2.0` (the formula declares
`license any_of: ["MIT", "Apache-2.0"]`). The 0.2.1 artifacts on PyPI still carry
`License: Proprietary` in their metadata because they were published before the
relicensing; the next release carries the dual licence. Nothing is sublicensed
by this tap.
