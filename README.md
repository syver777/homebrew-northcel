# Homebrew tap for NorthCel (.ncel)

`northcel` is the drawing language CLI for AI-drawn video: a `.ncel` scene is
parsed by a MoonBit typed-AST stage, its swarms are evaluated by Bend 0.2.38 /
HVM 2.0.22, and the contours are rasterised by GLSL 4.30 on Mesa's llvmpipe
through EGL — CPU only, no GPU. The Python reference parser/renderer installs
alongside as the conformance oracle.

```sh
brew tap syver777/northcel
brew install northcel

northcel doctor    # MoonBit, Bend/HVM2, GLSL and exact versions
northcel verify    # conformance frame + a six-frame film, rendered twice
```

`brew install syver777/northcel/northcel` is the same install without the
separate `brew tap` step.

## What it installs

Five sha256-pinned wheels into a private Homebrew venv — **nothing is compiled
and nothing is downloaded on first run**:

| Wheel | Size | Role |
| --- | ---: | --- |
| `ncel` 0.2.1 | 50 KB | the launcher (`northcel`): platform verdict, native dispatch, doctor/verify/check/info/render/film/fmt/guide |
| `ncel-native` 0.2.1 (`manylinux_2_39_x86_64`) | 2.8 MB | MoonBit stage, Bend 0.2.38, HVM 2.0.22, the EGL GL host, both GLSL shaders |
| `northcel` 0.2.1 | 140 KB | Python reference parser/validator/formatter (oracle; `fmt`; `--no-native`) |
| `numpy` 2.5.4, `pillow` 13.0.0 | 22 MB | required by the reference renderer |

Dependencies: `python@3.12` (the wheels are `cp312`) and `mesa` (libEGL +
llvmpipe — GLSL is compiled by the GL driver, so Mesa *is* the GLSL runtime).

`northcel` is the only install name; `ncel` is the short command alias the
package itself installs. Both run the same launcher.

## Platform support

| Platform | Status |
| --- | --- |
| Linux x86_64, glibc >= 2.39 (Ubuntu 24.04+, Debian 13, Fedora 40+, RHEL 10) | **supported, tested** |
| Linux x86_64, glibc < 2.39 | refused: the native wheel is `manylinux_2_39` |
| Linux aarch64 | refused: no aarch64 native artifact exists |
| macOS / Windows | refused: `depends_on :linux` + `depends_on arch: :x86_64` |

The formula refuses rather than installing something that cannot render. The
native runtime has never been built or verified on macOS: Apple's OpenGL stops
at 4.1, so the 4.30 shader cannot compile there; a macOS phase needs
Vulkan/MoltenVK or a tested GL 4.1 path first. `pip install ncel` still works on
macOS and labels its output as the non-native Python reference.

## Licence

The tap metadata (this repository) is MIT. The installed artifacts are dual
licensed `MIT OR Apache-2.0` (the formula declares
`license any_of: ["MIT", "Apache-2.0"]`). The 0.2.1 artifacts on PyPI still carry
`License: Proprietary` in their metadata because they were published before the
relicensing; the next release carries the dual licence. Nothing is sublicensed
by this tap.

## Uninstall

```sh
brew uninstall northcel        # removes the venv and both commands
brew untap syver777/northcel   # optional, removes this tap
```

Homebrew leaves its downloaded bottles/wheels in its own cache
(`$(brew --cache)`); `brew cleanup` clears them. The formula itself writes
nothing outside the Homebrew prefix: there is no `~/.local/share/ncel` state.

## Upgrading and maintenance

The version and every wheel sha256 are pinned in `Formula/northcel.rb`; bump the
version, the five hashes and the `test do` assertion together. `brew audit
--strict --formula Formula/northcel.rb` and `brew style Formula/northcel.rb` must
both pass before a formula change is pushed.
